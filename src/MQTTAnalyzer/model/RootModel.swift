//
//  x.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

class RootModel: ObservableObject {
	static let controller = MQTTSessionController()

	let sessionController = controller

	let hostsModel = HostsModel(initMethod: controller)

	var messageModelByHost: [Host: TopicTree] = [:]

	var hostModelsById: [String: Host] = [:]

	func getConnectionModel(broker: BrokerSetting) -> Host {
		let key = broker.id?.uuidString ?? "<no id>"
		var result = hostModelsById[key]

		if result == nil {
			result = Host(settings: broker)
			hostModelsById[key] = result
		}
		return result!
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
			model = createModel(for: host.settings.subscriptions?.subscriptions ?? [])
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

	#if os(iOS)
	private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
	#endif

	func scheduleBackgroundDisconnect(onDisconnect: @escaping () -> Void) {
		#if os(iOS)
		backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MQTTDisconnect") { [weak self] in
			// iOS is about to suspend — disconnect now to release file locks
			self?.disconnectAll()
			onDisconnect()
			self?.endBackgroundTask()
		}
		#else
		// macOS doesn't need background task management
		#endif
	}

	func cancelBackgroundDisconnect() {
		#if os(iOS)
		endBackgroundTask()
		#endif
	}

	#if os(iOS)
	private func endBackgroundTask() {
		if backgroundTaskID != .invalid {
			UIApplication.shared.endBackgroundTask(backgroundTaskID)
			backgroundTaskID = .invalid
		}
	}
	#endif

	func disconnectAll() {
		for host in hostModelsById.values where host.state != .disconnected {
			host.wasConnected = true
			disconnect(from: host)
		}
	}

	func reconnect() {
		for host in hostModelsById.values {
			if host.wasConnected && host.state == .disconnected {
				NSLog("Reconnecting to \(host)")
				connect(to: host)
			}
		}
	}
}
