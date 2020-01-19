//
//  MQTTSession.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine
import Moscapsule

class MQTTSession {
	static var sessionNum = 0
	let sessionNum: Int
	let model: MessageModel
	let host: Host
	var mqtt: MQTTClient?
	let messageSubject = PassthroughSubject<MQTTMessage, Never>()
	private var messageSubjectCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	var connectionFailed: String?
	var connected: Bool = false
	var connectionAlive: Bool {
		self.mqtt != nil || connected
	}
	
	init(host: Host, model: MessageModel) {
		MQTTSession.sessionNum += 1
		
		self.model = model
		self.sessionNum = MQTTSession.sessionNum
		self.host = host
	}
	
	func connect() {
		print("CONNECTION: connect \(sessionNum) \(host.hostname) \(host.topic)")
		host.connectionMessage = nil
		host.connecting = true
		connectionFailed = nil
		
		let mqttConfig = MQTTConfig(clientId: host.computeClientID, host: host.hostname, port: host.port, keepAlive: 60)
		mqttConfig.onConnectCallback = onConnect
		mqttConfig.onDisconnectCallback = onDisconnect
		mqttConfig.onMessageCallback = onMessage

		if host.auth {
			let username = host.usernameNonpersistent ?? host.username
			let password = host.passwordNonpersistent ?? host.password
			mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: username, password: password)
		}

		// create new MQTT Connection
		mqtt = MQTT.newConnection(mqttConfig)

		waitConnected()
		
		let queue = DispatchQueue(label: "Message dispache queue")
		messageSubjectCancellable = messageSubject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.5))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessageInMain(messages: $0)
			})
	}
	
	func disconnect() {
		print("CONNECTION: disconnect \(sessionNum) \(host.hostname) \(host.topic)")
		
		messageSubjectCancellable?.cancel()
		
		if let mqtt = self.mqtt {
			mqtt.unsubscribe(host.topic)
			mqtt.disconnect()
			
			waitDisconnected()
			
			print("CONNECTION: disconnected \(sessionNum) \(host.hostname) \(host.topic)")
		}
		setDisconnected()
	}
	
	func waitDisconnected() {
		let result = waitFor(predicate: { !self.connected })

		if result == .success {
			return
		}
		else {
			print("CONNECTION: disconnected timeout \(sessionNum): \(result)")
		}
	}
	
	func waitConnected() {
		
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			var i = 10
			while !self.connected && i > 0 && self.connectionFailed == nil {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname) \(self.host.topic)")
				sleep(1)
				DispatchQueue.main.async {
					self.host.connectionMessage = "Connecting... \(i)"
				}
				i-=1
			}
			group.leave()
		}

		group.notify(queue: .main) {
			if let errorMessage = self.connectionFailed {
				self.setDisconnected()
				self.host.connectionMessage = errorMessage
				return
			}
			
			if !self.host.connected {
				self.setDisconnected()
				
				self.host.connectionMessage = "Connection timeout"
			}
		}
	}
	
	func waitFor(predicate: @escaping () -> Bool) -> DispatchTimeoutResult {
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			while !predicate() {
				print("CONNECTION: waiting... \(self.sessionNum) \(self.host.hostname) \(self.host.topic)")
				usleep(useconds_t(500))
			}
			group.leave()
		}

		return group.wait(timeout: .now() + 10)
	}
	
	func setDisconnected() {
		connected = false
		DispatchQueue.main.async {
				self.host.connecting = false
		}
		messageSubjectCancellable = nil
		mqtt = nil
	}
	
	func onConnect(_ returnCode: ReturnCode) {
		print("CONNECTION: onConnect \(sessionNum) \(host.hostname) \(host.topic)")
		connected = true
		NSLog("Connected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.connecting = false
			self.host.connected = true
		}
		
		subscribeToChannel(host)
	}
	
	func onDisconnect(_ returnCode: ReasonCode) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname) \(host.topic)")
		
 		if returnCode == .mosq_conn_refused {
			NSLog("Connection refused")
			connectionFailed = "Connection refused"
			DispatchQueue.main.async {
				self.host.usernameNonpersistent = nil
				self.host.passwordNonpersistent = nil
				self.host.connectionMessage = "Connection refused"
			}
		}
		else {
			connectionFailed = returnCode.description
			DispatchQueue.main.async {
				self.host.connectionMessage = returnCode.description
			}
		}

		self.setDisconnected()
		
		NSLog("Disconnected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.pause = false
			self.host.connected = false
		}
	}
	
	func onMessage(_ message: MQTTMessage) {
		if !host.pause {
			messageSubject.send(message)
		}
	}
	
	func onMessageInMain(messages: [MQTTMessage]) {
		if host.pause {
			return
		}
		let date = Date()
		let mapped = messages.map({ (message: MQTTMessage) -> Message in
			let messageString = message.payloadString ?? ""
			return Message(data: messageString,
							  date: date,
							  qos: message.qos,
							  retain: message.retain,
							  topic: message.topic
			)
		})
		self.model.append(messages: mapped)
	}
	
	func subscribeToChannel(_ host: Host) {
		mqtt?.subscribe(host.topic, qos: 2)
	}
	
	func post(message: Message) {
		mqtt?.publish(string: message.data, topic: message.topic, qos: message.qos, retain: message.retain)
	}
}
