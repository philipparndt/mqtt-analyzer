//
//  MQTTController.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

class MQTTSessionController: ReconnectDelegate, DisconnectDelegate {
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
			session.host.connected = false
		}

		NSLog("MQTTController deinit")
	}
	
	func reconnect(host: Host) {
		DispatchQueue.main.async {
			host.connecting = true
		}
		
		if sessions[host.ID]?.connectionAlive ?? false {
			disconnect(host: host)
		}

		connect(host: host)
	}
	
	func connect(host: Host) {
		if model == nil {
			NSLog("model must be set in order to connect")
		}
		
		var session = sessions[host.ID]
		
		if session?.host !== host {
			disconnect(host: host)
			session = MqttClientCocoaMQTT(host: host, model: model!)
		}
		else if session?.connectionAlive ?? false {
			return
		}
		else if session?.connectionState.connected ?? false {
			reconnect(host: host)
			return
		}
		
		let current = session!
		if current.connectionAlive {
			return
		}
		current.connect()
		host.reconnectDelegate = self
		host.disconnectDelegate = self
		
		sessions[host.ID] = current
	}
	
	func disconnect(host: Host) {
		sessions[host.ID]?.disconnect()
		sessions.removeValue(forKey: host.ID)
	}
	
	func publish(message: Message, on: Host) {
		sessions[on.ID]?.publish(message: message)
	}
}
