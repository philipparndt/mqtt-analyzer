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

class MqttClientCocoaMQTT: MqttClient, WebSocketDelegate, CocoaMQTTDelegate {

	let sessionNum: Int
	let model: MessageModel
	var host: Host
	var mqtt: CocoaMQTT?
	
	var connectionAlive: Bool {
		self.mqtt != nil || connectionState.connected
	}
	
	var connectionState = ConnectionState()
	
	let messageSubject = MsgSubject<CocoaMQTTMessage>()
		
	init(host: Host, model: MessageModel) {
		ConnectionState.sessionNum += 1

		self.model = model
		self.sessionNum = ConnectionState.sessionNum
		self.host = host
	}
	
	func connect() {
		initConnect()
		
//		let websocket = CocoaMQTTWebSocket(uri: "/")
//		let mqtt = CocoaMQTT(clientID: host.computeClientID,
//							  host: host.hostname,
//							  port: host.port,
//							  socket: websocket)

		let mqtt = CocoaMQTT(clientID: host.computeClientID,
							  host: host.hostname,
							  port: host.port)
		
		mqtt.keepAlive = 60
		mqtt.delegate = self
		let sockedConnected = mqtt.connect()
		print("CONNECTION: socked \(sockedConnected)")
		
		self.mqtt = mqtt
		
		waitConnected()

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
			while self.connectionState.isConnecting && i > 0 {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname) \(self.host.topic)")
				sleep(1)

				self.setConnectionMessage(message: "Connecting... \(i)")

				i-=1
			}
			group.leave()
		}

		group.notify(queue: .main) {
			if let errorMessage = self.connectionState.connectionFailed {
				self.setDisconnected()
				self.host.connectionMessage = errorMessage
				return
			}

			if !self.host.connected {
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
		host.connecting = true
		connectionState.connectionFailed = nil
		connectionState.connecting = true
		
		model.limitMessagesPerBatch = host.limitMessagesBatch
		model.limitTopics = host.limitTopic
	}
	
	//	func connect() {
	//
	//		let mqttConfig = MQTTConfig(clientId: host.computeClientID, host: host.hostname, port: host.port, keepAlive: 60)
	//		mqttConfig.onConnectCallback = onConnect
	//		mqttConfig.onDisconnectCallback = onDisconnect
	//		mqttConfig.onMessageCallback = onMessage
	//
	//		if host.auth == .usernamePassword {
	//			let username = host.usernameNonpersistent ?? host.username
	//			let password = host.passwordNonpersistent ?? host.password
	//			mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: username, password: password)
	//		}
	//		else if host.auth == .certificate {
	//			let result = MQTTCertificateFiles.initCertificates(host: host, config: mqttConfig)
	//			if !result.0 {
	//				DispatchQueue.main.async {
	//					self.host.connecting = false
	//					self.host.connectionMessage = result.1
	//				}
	//				return
	//			}
	//		}
	//
	//		// create new MQTT Connection
	//		mqtt = MQTT.newConnection(mqttConfig)
	//
	//
	//	}
	
	func disconnect() {
		print("CONNECTION: disconnect \(sessionNum) \(host.hostname) \(host.topic)")

		messageSubject.cancel()

		if let mqtt = self.mqtt {
			mqtt.unsubscribe(host.topic)
			mqtt.disconnect()

			waitDisconnected()

			print("CONNECTION: disconnected \(sessionNum) \(host.hostname) \(host.topic)")
		}
		setDisconnected()
	}
	
	func waitDisconnected() {
		let result = waitFor(predicate: { !self.connectionState.connected })

		if result == .success {
			return
		}
		else {
			print("CONNECTION: disconnected timeout \(sessionNum): \(result)")
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
		connectionState.connected = false
		connectionState.connecting = false

		DispatchQueue.main.async {
			self.host.connecting = false
		}
		mqtt = nil
	}

	// MARK: Should be shared
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
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
			
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		
	}
	
	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname) \(host.topic)")

//		if returnCode == .mosq_conn_refused {
//			NSLog("Connection refused")
//			connectionState.connectionFailed = "Connection refused"
//			DispatchQueue.main.async {
//				self.host.usernameNonpersistent = nil
//				self.host.passwordNonpersistent = nil
//				self.host.connectionMessage = "Connection refused"
//			}
//		}
//		else {
//			connectionState.connectionFailed = returnCode.description
//			DispatchQueue.main.async {
//				self.host.connectionMessage = returnCode.description
//			}
//		}

		self.setDisconnected()

//		NSLog("Disconnected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.pause = false
			self.host.connected = false
		}
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		print("CONNECTION: onConnect \(sessionNum) \(host.hostname) \(host.topic)")
		connectionState.connected = true
		
		NSLog("Connected. Return Code is \(ack.description)")
		DispatchQueue.main.async {
			self.host.connecting = false
			self.host.connected = true
		}
		
		subscribeToTopic(host)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		if !host.pause {
			messageSubject.send(message)
		}
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
		
	}
	
	func websocketDidConnect(socket: WebSocketClient) {
		print("connected")
		
		mqtt?.publish(CocoaMQTTMessage(topic: "test", string: "hello from websocket"))
//		mqtt?.publish(CocoaMQTTMessage(topic: "test", string: "1234"))
	}
	
	func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
		print("disconnected")
	}
	
	func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
		
	}
	
	func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
		
	}

}
