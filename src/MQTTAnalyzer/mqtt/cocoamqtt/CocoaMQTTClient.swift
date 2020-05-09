//
//  MqttClientCocoaMQTT.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT
import Starscream
import Combine

class MqttClientCocoaMQTT: MqttClient {
	
	let delgate = MQTTDelegate()
	let utils = MqttClientSharedUtils()
	
	let sessionNum: Int
	let model: MessageModel
	var host: Host
	var mqtt: CocoaMQTT?
	
	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	var connectionState = ConnectionState()
	
	let messageSubject = MsgSubject<CocoaMQTTMessage>()
		
	init(host: Host, model: MessageModel) {
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
		mqtt.didChangeState = { mqtt, state in
			print(state)
		}
		
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
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname) \(self.host.topic)")
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
		print("CONNECTION: connect \(sessionNum) \(host.hostname) \(host.topic)")
		host.connectionMessage = nil
		host.state = .connecting
		connectionState.state = .connecting
		connectionState.message = nil
		
		model.limitMessagesPerBatch = host.limitMessagesBatch
		model.limitTopics = host.limitTopic
	}
		
	func disconnect() {
		print("CONNECTION: disconnect \(sessionNum) \(host.hostname) \(host.topic)")

		messageSubject.cancel()
		connectionState.state = .disconnected
		
		if let mqtt = self.mqtt {
			DispatchQueue.global(qos: .background).async {
				mqtt.unsubscribe(self.host.topic)
				mqtt.disconnect()

				DispatchQueue.main.async {
					print("CONNECTION: disconnected \(self.sessionNum) \(self.host.hostname) \(self.host.topic)")
					
					self.setDisconnected()
				}
			}
		}
	}
	
	func publish(message: Message) {
		mqtt?.publish(CocoaMQTTMessage(
			topic: message.topic,
			string: message.data,
			qos: convertQOS(qos: message.qos),
			retained: message.retain))
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
		let date = Date()
		let mapped = messages.map({ (message: CocoaMQTTMessage) -> Message in
			let messageString = message.string ?? ""
			return Message(data: messageString,
							  date: date,
							  qos: Int32(message.qos.rawValue),
							  retain: message.retained,
							  topic: message.topic
			)
		})
		self.model.append(messages: mapped)
	}
	
	// MARK: Should be shared
	func subscribeToTopic(_ host: Host) {
		mqtt?.subscribe(host.topic, qos: convertQOS(qos: Int32(host.qos)))
	}
	
	func extractErrorMessage(error: Error) -> String {
		if (error as NSError).code == 8 {
			return "Invalid hostname.\n\(error.localizedDescription)"
		}
		else {
			return error.localizedDescription
		}
	}
	
	func didDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname) \(host.topic)")

		if err != nil {
			connectionState.message = extractErrorMessage(error: err!)
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
			print("CONNECTION: onConnect \(sessionNum) \(host.hostname) \(host.topic)")
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
