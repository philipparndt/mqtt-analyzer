//
//  MQTTController.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

class MQTTSessionController: ReconnectDelegate, DisconnectDelegate, InitHost {
	
	var model: MessageModel?
	var sessions: [String: MqttClient] = [:]
	
	private var messageSubjectCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	
	init() {
		MqttClientMoscapsule.setup()
	}
	
	deinit {
		for session in self.sessions.values {
			session.host.state = .disconnected
		}

		NSLog("MQTTController deinit")
	}
	
	func initHost(host: Host) {
		if let session = sessions[host.ID] {
			host.disconnectDelegate = self
			host.reconnectDelegate = self
			host.state = session.connectionState.state
		}
	}
	
	func reconnect(host: Host) {
		DispatchQueue.main.async {
			host.state = .connecting
		}
		
		if sessions[host.ID]?.connectionAlive ?? false {
			disconnect(host: host)
		}

		connect(host: host)
	}
	
	fileprivate func createClient(_ host: Host) -> MqttClient {
		switch host.clientImpl {
		case .cocoamqtt:
			return MqttClientCocoaMQTT(host: host, model: model!)
		case .moscapsule:
			return MqttClientMoscapsule(host: host, model: model!)
		}
	}
	
	func connect(host: Host) {
		if model == nil {
			NSLog("model must be set in order to connect")
		}
		
		var session = sessions[host.ID]
		
		if session?.host !== host {
			disconnect(host: host)
			
			session = createClient(host)
		}
		else if session?.connectionAlive ?? false {
			host.state = session?.connectionState.state ?? .disconnected
			return
		}
		else {
			disconnect(host: host)
		}
		
		if let current = session {
			if current.connectionAlive {
				return
			}
			current.connect()
			host.reconnectDelegate = self
			host.disconnectDelegate = self
			
			sessions[host.ID] = current
		}
	}
	
	func disconnect(host: Host) {
		sessions[host.ID]?.disconnect()
		sessions.removeValue(forKey: host.ID)
	}
	
	func publish(message: Message, on: Host) {
		sessions[on.ID]?.publish(message: message)
	}
}
