//
//  MqttClientCocoaMQTT.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT
import Combine
import Network

class MqttClientCocoaMQTT: MqttClient {
	
	let delgate = MQTTDelegate()
	let utils = MqttClientSharedUtils()
	
	let sessionNum: Int
	let model: TopicTree
	var host: Host
	var mqtt: CocoaMQTT?
	
	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	var connectionState = ConnectionState()
	
	let messageSubject = MsgSubject<CocoaMQTTMessage>()
		
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
	
	func connect() {
		initConnect()
		
		let mqtt: CocoaMQTT
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: sanitizeBasePath(self.host.basePath))
			mqtt = CocoaMQTT(clientID: host.computeClientID,
								  host: host.hostname,
								  port: host.port,
								  socket: websocket)

		}
		else {
			mqtt = CocoaMQTT(clientID: host.computeClientID,
										  host: host.hostname,
										  port: host.port)
		}
		
		mqtt.enableSSL = host.ssl
		mqtt.allowUntrustCACertificate = host.untrustedSSL

		if host.auth == .usernamePassword {
			mqtt.username = host.usernameNonpersistent ?? host.username
			mqtt.password = host.passwordNonpersistent ?? host.password
		}
		else if host.auth == .certificate {
			do {
				try mqtt.sslSettings = createSSLSettings(host: host)
			}
			catch let error as CertificateError {
				failConnection(reason: "\(error.rawValue)")
				return
			}
			catch {
				failConnection(reason: "\(error)")
				return
			}
		}
		
		mqtt.keepAlive = 60
		mqtt.autoReconnect = false
		
		mqtt.delegate = self.delgate
		mqtt.didReceiveMessage = self.didReceiveMessage
		mqtt.didDisconnect = self.didDisconnect
		mqtt.didConnectAck = self.didConnect
		
		if !mqtt.connect() {
			failConnection(reason: "Connection to port \(host.port) failed")
			return
		}

		waitConnected()

		self.mqtt = mqtt

		let queue = DispatchQueue(label: "Message dispache queue")
		messageSubject.cancellable = messageSubject.subject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.5))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessageInMain(messages: $0)
			})
	}

	// MARK: Should be shared
	func waitConnected() {

		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			var i = 10
			
			while self.connectionState.state == .connecting && i > 0 {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname)")
				sleep(1)
				
				if self.connectionState.state == .connecting {
					self.setConnectionMessage(message: "Connecting... \(i)")
				}

				i-=1
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
	
	// MARK: Should be shared
	func setConnectionMessage(message: String) {
		DispatchQueue.global(qos: .userInitiated).async {
			DispatchQueue.main.async {
				self.host.connectionMessage = message
			}
		}
	}
	
	// MARK: Should be shared
	func initConnect() {
		print("CONNECTION: connect \(sessionNum) \(host.hostname)")
		host.connectionMessage = nil
		host.state = .connecting
		connectionState.state = .connecting
		connectionState.message = nil
		model.messageLimitExceeded = false
		model.topicLimitExceeded = false
	}
		
	func disconnect() {
		print("CONNECTION: disconnect \(sessionNum) \(host.hostname)")

		messageSubject.cancel()
		connectionState.state = .disconnected
		
		if let mqtt = self.mqtt {
			DispatchQueue.global(qos: .background).async {
				self.host.subscriptions.forEach { mqtt.unsubscribe($0.topic)}
				mqtt.disconnect()

				DispatchQueue.main.async {
					print("CONNECTION: disconnected \(self.sessionNum) \(self.host.hostname)")
					
					self.setDisconnected()
				}
			}
		}
	}
	
	func publish(message: MsgMessage) {
		mqtt?.publish(CocoaMQTTMessage(
			topic: message.topic.nameQualified,
			string: message.payload.dataString,
			qos: convertQOS(qos: message.metadata.qos),
			retained: message.metadata.retain))
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
	
	func setDisconnected() {
		connectionState.state = .disconnected

		DispatchQueue.main.async {
			self.host.state = .disconnected
		}
		mqtt = nil
	}

	// MARK: Should be shared
	func onMessageInMain(messages: [CocoaMQTTMessage]) {
		if host.pause {
			return
		}
		
		//		model.limitMessagesPerBatch = host.limitMessagesBatch
		//		model.limitTopics = host.limitTopic
		if messages.count > host.limitMessagesBatch {
			// Limit exceeded
			self.model.messageLimitExceeded = true
			return
		}
		
		for message in messages {
			if self.model.totalTopicCounter >= host.limitTopic {
				// Limit exceeded
				self.model.topicLimitExceeded = true
			}
			
			_ = self.model.addMessage(
				metadata: MsgMetadata(qos: Int32(message.qos.rawValue), retain: message.retained),
				payload: MsgPayload(data: message.payload),
				to: message.topic
			)
		}
	}
	
	// MARK: Should be shared
	func subscribeToTopic(_ host: Host) {
		host.subscriptions.forEach {
			mqtt?.subscribe($0.topic, qos: convertQOS(qos: Int32($0.qos)))
		}
	}
	
	func didDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname)")

		if err != nil {
			let messgae = MqttClientCocoaMQTT.extractErrorMessage(error: err!)
			
			connectionState.message = messgae
			DispatchQueue.main.async {
				self.host.usernameNonpersistent = nil
				self.host.passwordNonpersistent = nil
				self.host.connectionMessage = self.connectionState.message
			}
		}
		
		self.setDisconnected()

		DispatchQueue.main.async {
			self.host.pause = false
			self.host.state = .disconnected
		}
	}
	
	func didConnect(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		if ack == .accept {
			print("CONNECTION: onConnect \(sessionNum) \(host.hostname)")
			connectionState.state = .connected
			
			NSLog("Connected. Return Code is \(ack.description)")
			DispatchQueue.main.async {
				self.host.state = .connected
			}
			
			subscribeToTopic(host)
		}
		else if ack == .notAuthorized {
			self.host.usernameNonpersistent = nil
			self.host.passwordNonpersistent = nil
			failConnection(reason: "Not authorized")
		}
		else if ack == .badUsernameOrPassword {
			self.host.usernameNonpersistent = nil
			self.host.passwordNonpersistent = nil
			failConnection(reason: "Bad username/password")
		}
		else if ack == .unacceptableProtocolVersion {
			failConnection(reason: "Unacceptable protocol version")
		}
		else if ack == .identifierRejected {
			failConnection(reason: "Identifier rejected")
		}
		else if ack == .serverUnavailable {
			failConnection(reason: "Server unavailable")
		}
		else {
			failConnection(reason: "Unknown error")
		}
	}
	
	func failConnection(reason: String) {
		NSLog("Connection failed: " + reason)
		connectionState.message = reason
				
		self.setDisconnected()

		DispatchQueue.main.async {
			self.host.connectionMessage = reason
			self.host.pause = false
			self.host.state = .disconnected
		}
		
	}
	
	func didReceiveMessage(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		if !host.pause {
			messageSubject.send(message)
		}
	}

}
