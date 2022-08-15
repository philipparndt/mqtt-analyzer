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

@objc public enum HostAuthenticationType: Int32 {
	case none = 0
	case usernamePassword = 1
	case certificate = 2
	case both = 3
}

@objc public enum HostProtocol: Int32 {
	case mqtt = 0
	case websocket = 1
}

@objc public enum HostProtocolVersion: Int32 {
	case mqtt3 = 0
	case mqtt5 = 1
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

enum NavigationMode {
	case classic
	case folders
}

class Host: Identifiable, ObservableObject {
	
	let ID: String
	
	var subscriptionsReadable: String {
		return settings.subscriptions?
			.subscriptions
			.map { $0.topic }
			.joined(separator: ", ") ?? "<no subscription>"
	}
	
	let settings: BrokerSetting
	
	init(settings: BrokerSetting) {
		self.settings = settings
		self.ID = settings.id?.uuidString ?? ""
	}
	
	var computeClientID: String {
		let trimmed = settings.clientID?.trimmingCharacters(in: [" "]) ?? ""
		return trimmed.isBlank ? Host.randomClientId() : trimmed
	}
	
	@Published var usernameNonpersistent: String?
	@Published var passwordNonpersistent: String?
	
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

extension Host {
	var needsAuth: Bool {
		return settings.authType == .usernamePassword
		&& ((settings.username ?? "").isBlank || (settings.password ?? "").isBlank)
			&& (usernameNonpersistent == nil || passwordNonpersistent == nil)
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
			if $0.settings.alias != $1.settings.alias {
				return $0.settings.alias < $1.settings.alias
			}
			else {
				return $0.settings.aliasOrHost < $1.settings.aliasOrHost
			}
		}
	}
		
	init(hosts: [Host] = [], initMethod: InitHost) {
		self.initMethod = initMethod
		self.hosts = hosts
	}
	
	func getBroker(at offsets: IndexSet) -> Host? {
		if let first = offsets.first {
			return hostsSorted[first]
		}
		return nil
	}
}

extension Host {
	static func randomClientId() -> String {
		return "mqtt-analyzer-\(String.random(length: 8))"
	}
}
