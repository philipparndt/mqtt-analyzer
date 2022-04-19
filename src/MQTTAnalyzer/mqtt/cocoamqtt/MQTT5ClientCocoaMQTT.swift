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
	let delgate = MQTT5Delegate()
	var mqtt: CocoaMQTT5?

	let utils: ClientUtils
	var connectionState: ConnectionState { utils.connectionState }
	var host: Host { utils.host }

	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	let messageSubject = MsgSubject<CocoaMQTT5Message>()
		
	init(host: Host, model: TopicTree) {
		utils = ClientUtils(host: host, model: model)
	}
		
	func connect() {
		utils.initConnect()
		
		let mqtt: CocoaMQTT5
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: utils.sanitizeBasePath(self.host.basePath))
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

		self.mqtt = mqtt

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
		
		if let mqtt = self.mqtt {
			DispatchQueue.global(qos: .background).async {
				self.host.subscriptions.forEach { mqtt.unsubscribe($0.topic)}
				mqtt.disconnect()

				DispatchQueue.main.async {
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
			qos: utils.convertQOS(qos: message.metadata.qos),
			retained: message.metadata.retain
		)
		message.contentType = "application/json"
		mqtt?.publish(message, properties: properties)
	}
	
	func setDisconnected() {
		utils.setDisconnected()
		mqtt = nil
	}
	
	// MARK: Should be shared
	func subscribeToTopic(_ host: Host) {
		host.subscriptions.forEach {
			mqtt?.subscribe($0.topic, qos: utils.convertQOS(qos: Int32($0.qos)))
		}
	}

	func didDisconnect(_ mqtt: CocoaMQTT5, withError err: Error?) {
		utils.didDisconnect(withError: err)
	}
	
	func didConnect(_ mqtt: CocoaMQTT5, reasonCode: CocoaMQTTCONNACKReasonCode, didConnectAck ack: MqttDecodeConnAck) {
		
		switch reasonCode {
		case .success:
			utils.connectedSuccess()
			subscribeToTopic(host)
		case .badUsernameOrPassword:
			utils.clearAuth()
			utils.failConnection(reason: "Bad username/password")
		case .notAuthorized:
			utils.clearAuth()
			utils.failConnection(reason: "Not authorized")
		default:
			utils.failConnection(reason: String(describing: reasonCode))
		}
	}
		
	func didReceiveMessage(client: CocoaMQTT5, message: CocoaMQTT5Message, qos: UInt16, decode: MqttDecodePublish) {
		if !host.pause {
			messageSubject.send(message)
		}
	}

}
