//
//  HostModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

enum HostAuthenticationType {
	case none
	case usernamePassword
	case certificate
}

class Host: Identifiable, Hashable, ObservableObject {
	
	var ID: String = NSUUID().uuidString
	
	var deleted = false
	
	var alias: String = ""
	var hostname: String = ""
	var port: Int32 = 1883
	var topic: String = "#"

	var limitTopic = 250
	var limitMessagesBatch = 1000

	var clientID = Host.randomClientId()
	
	var computeClientID: String {
		let trimmed = clientID.trimmingCharacters(in: [" "])
		return trimmed.isBlank ? Host.randomClientId() : trimmed
	}
	
	var aliasOrHost: String {
		return alias.isBlank ? hostname : alias
	}
	
	var qos: Int = 0
	
	var auth: HostAuthenticationType = .none
	var username: String = ""
	var password: String = ""
	
	@Published var usernameNonpersistent: String?
	@Published var passwordNonpersistent: String?
	
	var needsAuth: Bool {
		return auth == .usernamePassword
			&& (username.isBlank || password.isBlank)
			&& (usernameNonpersistent == nil || passwordNonpersistent == nil)
	}
	
	@Published var connectionMessage: String?
	
	weak var reconnectDelegate: ReconnectDelegate?
	weak var disconnectDelegate: DisconnectDelegate?

	@Published var connected = false {
		didSet {
			if connected {
				wasConnected = true
			}
		}
	}
	
	@Published var connecting = false
	
	@Published var pause = false
	
	var wasConnected = false
	
	func reconnect() {
		reconnectDelegate?.reconnect(host: self)
	}
	
	func disconnect() {
		disconnectDelegate?.disconnect(host: self)
		connected = false
		usernameNonpersistent = nil
		passwordNonpersistent = nil
		wasConnected = false
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
