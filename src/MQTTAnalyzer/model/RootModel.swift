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
	
	var sessionController = MQTTSessionController()
	
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
		sessionController.host = to
		sessionController.model = messageModelByHost[to]
		sessionController.connect()
	}
	
	func disconnect() {
		sessionController.disconnect()
	}
	
	func post(message: Message) {
		sessionController.session?.post(message: message)
	}
}
