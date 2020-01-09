//
//  HostModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

class Host: Identifiable, Hashable, ObservableObject {
	
	var ID: String = NSUUID().uuidString
	
	var deleted = false
	
	var alias: String = ""
	var hostname: String = ""
	var port: Int32 = 1883
	var topic: String = "#"
	
	var qos: Int = 0
	
	var auth: Bool = false
	var username: String = ""
	var password: String = ""
	
	@Published var usernameNonpersistent: String?
	@Published var passwordNonpersistent: String?
	
	var needsAuth: Bool {
		return auth
			&& (username.isBlank || password.isBlank)
			&& (usernameNonpersistent == nil || passwordNonpersistent == nil)
	}
	
	@Published var connectionMessage: String?
	
	weak var reconnectDelegate: ReconnectDelegate?
	weak var disconnectDelegate: DisconnectDelegate?

	@Published var connected = false
	
	@Published var connecting = false
	
	@Published var pause = false
	
	func reconnect() {
		reconnectDelegate?.reconnect()
	}
	
	func disconnect() {
		disconnectDelegate?.disconnect()
		connected = false
		usernameNonpersistent = nil
		passwordNonpersistent = nil
	}
	
	static func == (lhs: Host, rhs: Host) -> Bool {
		return lhs.hostname == rhs.hostname
			&& lhs.topic == rhs.topic
			&& lhs.port == rhs.port
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(hostname)
		hasher.combine(port)
		hasher.combine(topic)
	}
}

class HostsModel: ObservableObject {
	@Published var hosts: [Host]
	
	init(hosts: [Host] = []) {
		self.hosts = hosts
	}
	
	func delete(at offsets: IndexSet, persistence: HostsModelPersistence) {
		let original = hosts
		
		for idx in offsets {
			persistence.delete(original[idx])
		}
		
		var copy = hosts
		copy.remove(atOffsets: offsets)
		self.hosts = copy
	}
	
	func delete(_ host: Host) {
		self.hosts = self.hosts.filter { $0 != host }
	}
}
