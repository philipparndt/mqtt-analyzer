//
//  MQTTController.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine
import Moscapsule

class MQTTSessionController: ReconnectDelegate, DisconnectDelegate {
	var model: MessageModel?
	var sessions: [Host: MQTTSession] = [:]
	
	private var messageSubjectCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	
	init() {
		// Init is necessary to provide SSL/TLS functions.
		moscapsule_init()
	}
	
	deinit {
		for host in self.sessions.keys {
			DispatchQueue.main.async {
				host.connected = false
			}
		}

		NSLog("MQTTController deinit")
	}
	
	func reconnect(host: Host) {
		DispatchQueue.main.async {
			host.connecting = true
		}
		
		if sessions[host]?.connectionAlive ?? false {
			disconnect(host: host)
		}

		connect(host: host)
	}
	
	func connect(host: Host) {
		if model == nil {
			NSLog("model must be set in order to connect")
		}
		
		var session = sessions[host]
		
		if session?.host !== host {
			disconnect(host: host)
			session = MQTTSession(host: host, model: model!)
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
		
		sessions[host] = current
	}
	
	func disconnect(host: Host) {
		sessions[host]?.disconnect()
		sessions.removeValue(forKey: host)
	}
	
	func publish(message: Message, on: Host) {
		sessions[on]?.publish(message: message)
	}
}
