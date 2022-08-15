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
	let delegate = MQTTDelegate()

	let utils: ClientUtils<CocoaMQTT, CocoaMQTTMessage>
	var connectionState: ConnectionState { utils.connectionState }
	var host: Host { utils.host }
	var connectionAlive: Bool { utils.connectionAlive }
		
	init(host: Host, model: TopicTree) {
		utils = ClientUtils(host: host, model: model)
	}
		
	func connect() {
		utils.initConnect()
		
		let mqtt = createClient(host: host)
		do {
			try configureClient(client: mqtt)
		}
		catch let error as CertificateError {
			utils.failConnection(reason: "\(error.rawValue)")
			return
		}
		catch {
			utils.failConnection(reason: "\(error)")
			return
		}
		
		mqtt.delegate = self.delegate
		mqtt.didReceiveMessage = self.didReceiveMessage
		mqtt.didDisconnect = utils.didDisconnect(_:withError:)
		mqtt.didConnectAck = self.didConnect
		
		if !mqtt.connect() {
			utils.failConnection(reason: "Connection to port \(host.settings.port) failed")
			return
		}

		utils.waitConnected()
		utils.mqtt = mqtt

		utils.installMessageDispatch(
			metadata: metadata(of:),
			payload: payload(of:),
			topic: topic(of:)
		)
	}
	
	func configureClient(client mqtt: CocoaMQTT) throws {
		mqtt.enableSSL = host.settings.ssl
		mqtt.allowUntrustCACertificate = host.settings.untrustedSSL

		if host.settings.authType == .usernamePassword || host.settings.authType == .both {
			mqtt.username = host.actualUsername
			mqtt.password = host.actualPassword
		}
		
		if host.settings.authType == .certificate || host.settings.authType == .both {
			try mqtt.sslSettings = createSSLSettings(host: host)
		}
		
		mqtt.keepAlive = 60
		mqtt.autoReconnect = false
	}
			
	func disconnect() {
		utils.messageSubject.cancel()

		if let mqtt = utils.mqtt {
			DispatchQueue.global(qos: .background).async {
				(self.host.settings.subscriptions?.subscriptions ?? []).forEach { mqtt.unsubscribe($0.topic)}
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
	
	func subscribeToTopic(_ host: Host) {
		(self.host.settings.subscriptions?.subscriptions ?? []).forEach {
			utils.mqtt?.subscribe($0.topic, qos: utils.convertQOS(qos: Int32($0.qos)))
		}
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
	
	func didReceiveMessage(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, qos: UInt16) {
		let rmessage = ReceivedMessage(
			message: message
		)
		utils.didReceiveMessage(message: rmessage)
	}
}
