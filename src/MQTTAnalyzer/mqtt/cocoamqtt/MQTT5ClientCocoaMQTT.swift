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

class MQTT5ClientCocoaMQTT: MqttClient {
	private let connectionStateQueue = DispatchQueue(label: "connection.state.lock.queue")
	
	let delgate = MQTT5Delegate()
	
	let sessionNum: Int
	let model: TopicTree
	var host: Host
	var mqtt: CocoaMQTT5?
	
	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	var connectionState = ConnectionState()
	
	let messageSubject = MsgSubject<CocoaMQTT5Message>()
		
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
		
		let mqtt: CocoaMQTT5
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: sanitizeBasePath(self.host.basePath))
			mqtt = CocoaMQTT5(clientID: host.computeClientID,
								  host: host.hostname,
								  port: host.port,
								  socket: websocket)

		}
		else {
			mqtt = CocoaMQTT5(clientID: host.computeClientID,
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
		self.connectionStateQueue.async {
			self.connectionState.state = .disconnected
		}
		
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
		let properties: MqttPublishProperties = MqttPublishProperties()
		let message = CocoaMQTT5Message(
			topic: message.topic.nameQualified,
			string: message.payload.dataString,
			qos: convertQOS(qos: message.metadata.qos),
			retained: message.metadata.retain
		)
		message.contentType = "application/json"
		mqtt?.publish(message, properties: properties)
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
		self.connectionStateQueue.async {
			self.connectionState.state = .disconnected
		}

		DispatchQueue.main.async {
			self.host.state = .disconnected
		}
		mqtt = nil
	}

	// MARK: Should be shared
	func onMessageInMain(messages: [CocoaMQTT5Message]) {
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
			if host.limitTopic > 0 && self.model.totalTopicCounter >= host.limitTopic {
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

	func didDisconnect(_ mqtt: CocoaMQTT5, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname)")

		if err != nil {
			let messgae = MQTTClientCocoaMQTT.extractErrorMessage(error: err!)
			
			self.connectionStateQueue.async {
				self.connectionState.message = messgae
			}
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
	
	func didConnect(_ mqtt: CocoaMQTT5, reasonCode: CocoaMQTTCONNACKReasonCode, didConnectAck ack: MqttDecodeConnAck) {
		
		switch reasonCode {
		case .success:
			connectedSuccess(didConnectAck: ack)
		case .badUsernameOrPassword:
			clearAuth()
			failConnection(reason: "Bad username/password")
		case .notAuthorized:
			clearAuth()
			failConnection(reason: "Not authorized")
		default:
			failConnection(reason: String(describing: reasonCode))
		}
	}
	
	func connectedSuccess(didConnectAck ack: MqttDecodeConnAck) {
		print("CONNECTION: onConnect \(sessionNum) \(host.hostname)")
		self.connectionStateQueue.async {
			self.connectionState.state = .connected
		}

		NSLog("Connected. Return Code is \(ack.description)")
		DispatchQueue.main.async {
			self.host.state = .connected
		}
		
		subscribeToTopic(host)
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
	
	func didReceiveMessage(client: CocoaMQTT5, message: CocoaMQTT5Message, qos: UInt16, decode: MqttDecodePublish) {
		if !host.pause {
			messageSubject.send(message)
		}
	}

}
