//
//  x.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine

class RootModel: ObservableObject {
	static let controller = MQTTSessionController()
	
	let sessionController = controller

	let hostsModel = HostsModel(initMethod: controller)
	
	var messageModelByHost: [Host: TopicTree] = [:]
	
	let persistence: Persistence
	
	init() {
		if CommandLine.arguments.contains("--ui-testing") {
			self.persistence = StubPersistence(model: hostsModel)
		}
		else {
			if let persistence = RealmPersistence(model: hostsModel) {
				self.persistence = persistence
			}
			else {
				self.persistence = StubPersistence(model: hostsModel)
			}
		}

		self.persistence.load()
	}
 
	func createModel(for subscriptions: [TopicSubscription]) -> TopicTree {
		let prefix = TreeUtils.commomPrefix(subscriptions: subscriptions.map { $0.topic })
		var model = TopicTree()
		if !prefix.isEmpty {
			model = model.addTopic(topic: prefix) ?? model
		}
		
		return model
	}
	
	func getMessageModel(_ host: Host) -> TopicTree {
		var model = messageModelByHost[host]
		
		if model == nil {
			model = createModel(for: host.subscriptions)
			messageModelByHost[host] = model
		}
		
		return model!
	}
	
	func connect(to: Host) {
		to.state = .connecting
		sessionController.model = messageModelByHost[to]
		sessionController.connect(host: to)
	}
	
	func disconnect(from: Host) {
		sessionController.disconnect(host: from)
	}
	
	func publish(message: MsgMessage, on: Host) {
		sessionController.publish(message: message, on: on)
	}
	
	func reconnect() {
		for host in hostsModel.hosts {
			if host.wasConnected && host.state == .disconnected {
				connect(to: host)
			}
		}
	}
}
