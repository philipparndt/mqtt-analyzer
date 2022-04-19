//
//  ClientUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

class ClientUtils<T, M> {
	let connectionStateQueue = DispatchQueue(label: "connection.state.lock.queue")
	var connectionState = ConnectionState()
	let messageSubject = MsgSubject<ReceivedMessage<M>>()
	
	var host: Host
	let sessionNum: Int
	let model: TopicTree
	var mqtt: T?
	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	init(host: Host, model: TopicTree) {
		ConnectionState.sessionNum += 1
		self.model = model
		self.sessionNum = ConnectionState.sessionNum
		self.host = host
	}
	
	func sanitizeBasePath(_ basePath: String) -> String {
		if basePath.starts(with: "/") {
			return basePath
		}
		else {
			return "/\(basePath)"
		}
	}
	
	func convertQOS(qos: Int32) -> CocoaMQTTQoS {
		switch qos {
		case 1:
			return CocoaMQTTQoS.qos1
		case 2:
			return CocoaMQTTQoS.qos2
		default:
			return CocoaMQTTQoS.qos0
		}
	}
	
	func connectedSuccess() {
		print("CONNECTION: onConnect \(sessionNum) \(host.hostname)")
		self.connectionStateQueue.async {
			self.connectionState.state = .connected
		}

		NSLog("Connected.")
		DispatchQueue.main.async {
			self.host.state = .connected
		}
	}
	
	func clearAuth() {
		self.host.usernameNonpersistent = nil
		self.host.passwordNonpersistent = nil
	}
	
	func failConnection(reason: String) {
		NSLog("Connection failed: " + reason)
		self.connectionStateQueue.async {
			self.connectionState.message = reason
		}

		self.setDisconnected()

		DispatchQueue.main.async {
			self.host.connectionMessage = reason
			self.host.pause = false
			self.host.state = .disconnected
		}
		
	}
	
	func initConnect() {
		print("CONNECTION: connect \(sessionNum) \(host.hostname)")
		host.connectionMessage = nil
		host.state = .connecting
		connectionState.state = .connecting
		connectionState.message = nil
		model.messageLimitExceeded = false
		model.topicLimitExceeded = false
	}
	
	func didDisconnect(_ client: T, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname)")

		if err != nil {
			let message = ClientUtils.extractErrorMessage(error: err!)
			
			self.connectionStateQueue.async {
				self.connectionState.message = message
			}
			DispatchQueue.main.async {
				self.host.usernameNonpersistent = nil
				self.host.passwordNonpersistent = nil
				self.host.connectionMessage = self.connectionState.message
			}
		}
		
		DispatchQueue.main.async {
			self.host.pause = false
			self.host.state = .disconnected
		}
		
		setDisconnected()
	}
	
	func setDisconnected() {
		print("CONNECTION: disconnected \(self.sessionNum) \(self.host.hostname)")
		
		self.connectionStateQueue.async {
			self.connectionState.state = .disconnected
		}

		DispatchQueue.main.async {
			self.host.state = .disconnected
		}
		
		mqtt = nil
	}
	
	func installMessageDispatch(metadata: @escaping ((M) -> MsgMetadata), payload: @escaping((M) -> MsgPayload), topic: @escaping ((M) -> String)) {
		let queue = DispatchQueue(label: "Message Dispatch queue")
		messageSubject.cancellable = messageSubject.subject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.5))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessages(messages: $0, metadata: metadata, payload: payload, topic: topic)
			})
	}
	
	func didReceiveMessage(message: ReceivedMessage<M>) {
		if !host.pause {
			messageSubject.send(message)
		}
	}
	
	func receiveMessagePreflight(amount: Int) -> Bool {
		if host.pause {
			return false
		}
		
		if amount > host.limitMessagesBatch {
			// Limit exceeded
			self.model.messageLimitExceeded = true
			return false
		}
		
		return true
	}
	
	func onMessages<M>(messages: [ReceivedMessage<M>], metadata: ((M) -> MsgMetadata), payload: ((M) -> MsgPayload), topic: ((M) -> String)) {
		if !receiveMessagePreflight(amount: messages.count) {
			return
		}
		
		for rmessage in messages {
			if host.limitTopic > 0 && self.model.totalTopicCounter >= host.limitTopic {
				// Limit exceeded
				self.model.topicLimitExceeded = true
			}
			
			let message = rmessage.message
			let messageMetadata = metadata(message)
			messageMetadata.userProperty = rmessage.userProperty
			messageMetadata.responseTopic = rmessage.responseTopic
			
			let messagePayload = payload(message)
			messagePayload.contentType = rmessage.contentType
			
			_ = self.model.addMessage(
				metadata: messageMetadata,
				payload: messagePayload,
				to: topic(message)
			)
		}
	}
	
	func waitConnected() {
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			var i = 10
			
			var connecting = true
			
			while connecting && i > 0 {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname)")
				sleep(1)
				
				i-=1
				
				self.connectionStateQueue.sync {
					connecting = self.connectionState.state == .connecting
				}
			}
			group.leave()
		}

		group.notify(queue: .main) {
			if let errorMessage = self.connectionState.message {
				self.setDisconnected()
				self.host.connectionMessage = errorMessage
				return
			}

			if self.host.state != .connected {
				self.setDisconnected()

				self.setConnectionMessage(message: "Connection timeout")
			}
		}
	}
	
	func setConnectionMessage(message: String) {
		DispatchQueue.main.async {
			self.host.connectionMessage = message
		}
	}
	
	class func extractErrorMessage(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		
		if code == 8 {
			return "Invalid hostname.\n\(error.localizedDescription)"
		}
		else if nsError.domain == "Network.NWError" {
			if nsError.description.starts(with: "-9808") {
				return "Bad certificate format, check all properties, like SAN, ... (-9808)"
			}
			else {
				let groups = nsError.description.groups(for: ".*\\(rawValue:.(\\d+)\\):.(.*)")
				if groups.count == 1 && groups[0].count == 3 {
					return "\(groups[0][2]) (NW: \(groups[0][1]))"
				}
			}
		}
		
		return "\(nsError.domain): \(nsError.description)"
	}
}
