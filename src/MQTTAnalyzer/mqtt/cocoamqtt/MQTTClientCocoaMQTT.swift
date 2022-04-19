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

class MQTTClientCocoaMQTT: MqttClient {
	let delgate = MQTTDelegate()

	let utils: ClientUtils<CocoaMQTT>
	var connectionState: ConnectionState { utils.connectionState }
	var host: Host { utils.host }
	var connectionAlive: Bool { utils.connectionAlive }
	
	let messageSubject = MsgSubject<CocoaMQTTMessage>()
		
	init(host: Host, model: TopicTree) {
		utils = ClientUtils(host: host, model: model)
	}
		
	func connect() {
		utils.initConnect()
		
		let mqtt: CocoaMQTT
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: utils.sanitizeBasePath(self.host.basePath))
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
				utils.failConnection(reason: "\(error.rawValue)")
				return
			}
			catch {
				utils.failConnection(reason: "\(error)")
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
			utils.failConnection(reason: "Connection to port \(host.port) failed")
			return
		}

		utils.waitConnected()

		utils.mqtt = mqtt

		let queue = DispatchQueue(label: "Message Dispatch queue")
		messageSubject.cancellable = messageSubject.subject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.5))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessageInMain(messages: $0)
			})
	}
			
	func disconnect() {
		messageSubject.cancel()

		if let mqtt = utils.mqtt {
			DispatchQueue.global(qos: .background).async {
				self.host.subscriptions.forEach { mqtt.unsubscribe($0.topic)}
				mqtt.disconnect()

				DispatchQueue.main.async {
					self.utils.setDisconnected()
				}
			}
		}
	}
	
	func publish(message: MsgMessage) {
		utils.mqtt?.publish(CocoaMQTTMessage(
			topic: message.topic.nameQualified,
			string: message.payload.dataString,
			qos: utils.convertQOS(qos: message.metadata.qos),
			retained: message.metadata.retain))
	}
	
	// MARK: Should be shared
	func subscribeToTopic(_ host: Host) {
		host.subscriptions.forEach {
			utils.mqtt?.subscribe($0.topic, qos: utils.convertQOS(qos: Int32($0.qos)))
		}
	}
	
	func didDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		utils.didDisconnect(withError: err)
	}
	
	func didConnect(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		switch ack {
		case .accept:
			utils.connectedSuccess()
			subscribeToTopic(host)
		case .badUsernameOrPassword:
			utils.clearAuth()
			utils.failConnection(reason: "Bad username/password")
		case .notAuthorized:
			utils.clearAuth()
			utils.failConnection(reason: "Not authorized")
		default:
			utils.failConnection(reason: String(describing: ack))
		}
	}
	
	func didReceiveMessage(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		if !host.pause {
			messageSubject.send(message)
		}
	}

}
