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
	let model: MessageModel
	let host: Host
	var mqtt: MQTTClient?
	let messageSubject = PassthroughSubject<MQTTMessage, Never>()
	private var messageSubjectCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	var connected: Bool = false
	var connectionAlive: Bool {
		self.mqtt != nil || connected
	}
	
	init(host: Host, model: MessageModel) {
		self.model = model
		self.host = host
	}
	
	func connect() {
		host.connectionMessage = nil
		
		let mqttConfig = MQTTConfig(clientId: clientID(), host: host.hostname, port: host.port, keepAlive: 60)
		mqttConfig.onConnectCallback = onConnect
		mqttConfig.onDisconnectCallback = onDisconnect
		mqttConfig.onMessageCallback = onMessage

		if host.auth {
			mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: host.username, password: host.password)
		}

		// create new MQTT Connection
		mqtt = MQTT.newConnection(mqttConfig)

		let queue = DispatchQueue(label: "Message dispache queue")
		messageSubjectCancellable = messageSubject.eraseToAnyPublisher()
		.collect(.byTime(queue, 0.5))
		.receive(on: DispatchQueue.main)
		.sink(receiveValue: {
			self.onMessageInMain(messages: $0)
		})
		
		subscribeToChannel(host)
	}
	
	func disconnect() {
		messageSubjectCancellable?.cancel()
		mqtt?.unsubscribe(host.topic)
		mqtt?.disconnect()
		connected = false
		messageSubjectCancellable = nil
		mqtt = nil
	}
	
	func onConnect(_ returnCode: ReturnCode) {
		NSLog("Connected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.connected = true
		}
	}
	
	func onDisconnect(_ returnCode: ReasonCode) {
 		if returnCode == .mosq_conn_refused {
			NSLog("Connection refused")
			host.connectionMessage = "Connection refused"
		}
		else {
		   host.connectionMessage = returnCode.description
		}

		self.disconnect()
		
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
		
		let mapped = messages.map({ (message: MQTTMessage) -> Message in
			let messageString = message.payloadString ?? ""
			return Message(data: messageString,
							  date: Date(),
							  qos: message.qos,
							  retain: message.retain,
							  topic: message.topic
			)
		})
		self.model.append(messges: mapped)
	}
	
	func subscribeToChannel(_ host: Host) {
		mqtt?.subscribe(host.topic, qos: 2)
	}
	
	func post(message: Message) {
		mqtt?.publish(string: message.data, topic: message.topic, qos: message.qos, retain: message.retain)
	}
	
	// MARK: - Utilities
	
	func clientID() -> String {
		let userDefaults = UserDefaults.standard
		let clientIDPersistenceKey = "clientID"
		let clientID: String

		if let savedClientID = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
			clientID = savedClientID
		} else {
			clientID = "MQTTAnalyzer_" + randomStringWithLength(10)
			userDefaults.set(clientID, forKey: clientIDPersistenceKey)
			userDefaults.synchronize()
		}

		return clientID
	}
	
	// http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
	func randomStringWithLength(_ length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map { _ in letters.randomElement()! })
	}
}
