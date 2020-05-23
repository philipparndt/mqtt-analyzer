//
//  HostModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

enum CertificateLocation: Int, Codable {
	case cloud = 0
	case local = 1
}

enum CertificateFileType: Int, Codable {
	case p12 = 0
	case serverCA = 1
	case client = 2
	case clientKey = 3
	case undefined = 4
}

extension CertificateFileType {
	func getName() -> String {
		switch self {
		case .p12:
			return "Client PKCS#12"
		case .serverCA:
			return "Server CA"
		case .client:
			return "Client Certificate"
		case .clientKey:
			return "Client Key"
		case .undefined:
			return "Undefined"
		}
	}
}

enum HostAuthenticationType {
	case none
	case usernamePassword
	case certificate
}

enum HostProtocol {
	case mqtt
	case websocket
}

enum HostClientImplType {
	case moscapsule
	case cocoamqtt
}

extension Host: Hashable {
	static func == (lhs: Host, rhs: Host) -> Bool {
		return lhs.ID == rhs.ID
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.ID)
	}
}

struct TopicSubscription: Codable {
	var topic: String
	var qos: Int
}

struct CertificateFile: Codable {
	let name: String
	let location: CertificateLocation
	var type = CertificateFileType.undefined
}

struct MessageTemplateMessage {
	var topic: String
	var message: String
}

class MessageTemplate: Identifiable {
	let id = UUID.init()
	var name: String
	var messages: [MessageTemplateMessage]
	
	init(name: String, messages: [MessageTemplateMessage]) {
		self.name = name
		self.messages = messages
	}
}

class Host: Identifiable, ObservableObject {
	
	let ID: String
	
	var deleted = false
	
	var alias: String = ""
	var hostname: String = ""
	var port: UInt16 = 1883
	var subscriptions: [TopicSubscription] = [TopicSubscription(topic: "#", qos: 0)]
	var subscriptionsReadable: String {
		return subscriptions.map { $0.topic }.joined(separator: ", ")
	}
	
	var protocolMethod: HostProtocol = .mqtt
	var clientImpl: HostClientImplType = .cocoamqtt
	var basePath: String = ""
	var ssl: Bool = false
	var untrustedSSL: Bool = false
	
	var limitTopic = 250
	var limitMessagesBatch = 1000

	var clientID = ""
	
	var templates: [MessageTemplate] = [
		MessageTemplate(name: "tpl-a", messages: [
			MessageTemplateMessage(topic: "tpl-a/a1", message: "test-a1"),
			MessageTemplateMessage(topic: "tpl-a/a2", message: "test-a2"),
			MessageTemplateMessage(topic: "tpl-a/a3", message: "test-a3"),
			MessageTemplateMessage(topic: "tpl-a/a4", message: "test-a4"),
			MessageTemplateMessage(topic: "tpl-a/a5", message: "test-a5"),
			MessageTemplateMessage(topic: "tpl-a/a6", message: "test-a6"),
			MessageTemplateMessage(topic: "tpl-a/a7", message: "test-a7"),
			MessageTemplateMessage(topic: "tpl-a/a8", message: "test-a8"),
			MessageTemplateMessage(topic: "tpl-a/a9", message: "test-a9"),
			MessageTemplateMessage(topic: "tpl-a/a10", message: "test-a10"),
			MessageTemplateMessage(topic: "tpl-a/a11", message: "test-a11"),
			MessageTemplateMessage(topic: "tpl-a/a12", message: "test-a12"),
			MessageTemplateMessage(topic: "tpl-a/a13", message: "test-a13"),
			MessageTemplateMessage(topic: "tpl-a/a14", message: "test-a14")
		]),
		MessageTemplate(name: "tpl-b", messages: [
		]),
		MessageTemplate(name: "tpl-c", messages: [
		])
	]
	
	init(id: String = NSUUID().uuidString) {
		self.ID = id
	}
	
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
	
	var certificates: [CertificateFile] = []
	var certClientKeyPassword: String = ""
	
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
	
	@Published var state: MQTTConnectionState = .disconnected {
		didSet {
			if state == .connected {
				wasConnected = true
			}
		}
	}
	
	@Published var pause = false
	
	var wasConnected = false
	
	func reconnect() {
		reconnectDelegate?.reconnect(host: self)
	}
	
	func disconnect() {
		disconnectDelegate?.disconnect(host: self)
		state = .disconnected
		
		usernameNonpersistent = nil
		passwordNonpersistent = nil
		wasConnected = false
	}

}

class HostsModel: ObservableObject {
	let initMethod: InitHost
	
	@Published var hosts: [Host] {
		willSet {
			for host in newValue {
				initMethod.initHost(host: host)
			}
		}
	}
	
	var hostsSorted: [Host] {
		return self.hosts.sorted {
			if $0.alias != $1.alias {
				return $0.alias < $1.alias
			}
			else {
				return $0.aliasOrHost < $1.aliasOrHost
			}
		}
	}
	
	var hasDeprecated: Bool {
		return self.hosts.filter { $0.clientImpl == .moscapsule }.first != nil
	}
	
	init(hosts: [Host] = [], initMethod: InitHost) {
		self.initMethod = initMethod
		self.hosts = hosts
	}
	
	func delete(at offsets: IndexSet, persistence: HostsModelPersistence) {
		let original = hostsSorted
				
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
