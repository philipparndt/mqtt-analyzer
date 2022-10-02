//
//  HostSetting.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-21.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

import CloudKit

struct AuthenticationType {
	static let none: Int8 = 0
	static let usernamePassword: Int8 = 1
	static let certificate: Int8 = 2
}

struct ConnectionMethod {
	static let mqtt: Int8 = 0
	static let websocket: Int8 = 1
}

struct HostProtocolVersionType {
	static let mqtt3: Int8 = 0
	static let mqtt5: Int8 = 1
}

struct NavigationModeType {
	static let folders: Int8 = 0
	static let classic: Int8 = 1
}

extension BrokerSetting {
	var aliasOrHost: String {
		let a = alias
		if a.trimmingCharacters(in: [" "]).isBlank {
			return hostname
		}
		return a
	}
}
