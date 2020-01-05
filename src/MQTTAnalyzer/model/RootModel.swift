//
//  x.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine

protocol ReconnectDelegate: class {
	func reconnect()
}

class RootModel: ObservableObject {
	let hostsModel = HostsModel()
	
	var messageModelByHost: [Host: MessageModel] = [:]
	
	var currentSession: MQTTSessionController?
	
	let persistence: HostsModelPersistence
	
	init() {
		self.persistence = HostsModelPersistence(model: hostsModel)
		self.persistence.load()
		
		for host in hostsModel.hosts {
			messageModelByHost[host] = MessageModel()
		}
	}
 
	func getMessageModel(_ host: Host) -> MessageModel {
		var model = messageModelByHost[host]
		
		if model == nil {
			model = MessageModel()
			messageModelByHost[host] = model
		}
		
		return model!
	}
	
	func connect(to: Host) {
		if currentSession != nil {
			let session = currentSession!
			if session.host == to {
				if !session.connected {
					print("Reconnecting to " + session.host.hostname)
					session.reconnect()
				}
				return
			}
			else {
				print("Disconnecting from " + session.host.hostname)
				session.disconnect()
			}
		}
		
		print("Connecting to " + to.hostname)
		let model = messageModelByHost[to]
		if model != nil {
			currentSession = MQTTSessionController(host: to, model: model!)
		}
		
		currentSession?.connect()
	}
	
	func disconnect() {
		currentSession?.disconnect()
	}
	
	func post(message: Message) {
		currentSession?.post(message: message)
	}
}
