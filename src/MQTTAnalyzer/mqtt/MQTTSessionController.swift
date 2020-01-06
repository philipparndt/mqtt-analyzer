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

class MQTTSessionController: ReconnectDelegate {
	var model: MessageModel?
	var host: Host? {
		didSet {
			if let current = self.host {
				current.reconnectDelegate = self
			}
		}
	}
	var session: MQTTSession?
	
	private var messageSubjectCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	
	deinit {
		let host = self.host
		DispatchQueue.main.async {
			host?.connected = false
		}
		NSLog("MQTTController deinit")
	}
	
	func reconnect() {
		DispatchQueue.main.async {
			self.host?.connecting = true
		}
		
		if session?.connectionAlive ?? false {
			disconnect()
		}

		connect()
	}
	
	func connect() {
		if host == nil {
			NSLog("host must be set in order to connect")
		}
		
		if model == nil {
			NSLog("model must be set in order to connect")
		}
		
		if session?.host !== host {
			disconnect()
			session = MQTTSession(host: host!, model: model!)
		}
		else if session?.connected ?? false {
			reconnect()
			return
		}
		
		let current = session!
		if current.connectionAlive {
			return
		}
		current.connect()
	}
	
	func disconnect() {
		session?.disconnect()
		session = nil
	}
}
