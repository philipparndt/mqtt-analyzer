//
//  HostSetting.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-21.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

import RealmSwift
import IceCream
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

struct ClientImplType {
	static let moscapsule: Int8 = 0
	static let cocoamqtt: Int8 = 1
}

struct NavigationModeType {
	static let folders: Int8 = 0
	static let classic: Int8 = 1
}

class HostSetting: Object {
	@Persisted(primaryKey: true) var id = NSUUID().uuidString
	@Persisted var alias = ""
	@Persisted var hostname = ""
	@Persisted var port: Int32 = 1883

	@Persisted var subscriptions: Data = Data()

	@Persisted var protocolMethod: Int8 = ConnectionMethod.mqtt
	@Persisted var basePath: String = ""
	@Persisted var ssl: Bool = false
	@Persisted var untrustedSSL: Bool = false
	
	@Persisted var clientImplType: Int8 = ClientImplType.cocoamqtt
	
	@Persisted var authType: Int8 = AuthenticationType.none
	@Persisted var username: String = ""
	@Persisted var password: String = ""
	
	@Persisted var certificates: Data = Data()
	@Persisted var certClientKeyPassword: String = ""

	@Persisted var clientID = Host.randomClientId()

	@Persisted var limitTopic = 250
	@Persisted var limitMessagesBatch = 1000

	@Persisted var navigationMode: Int8 = NavigationModeType.folders
	@Persisted var maxMessagesOfSubFolders = 10
	
	@Persisted var isDeleted = false
}

extension Host {
	static func randomClientId() -> String {
		return "mqtt-analyzer-\(String.random(length: 8))"
	}
}

extension HostSetting: CKRecordConvertible {
}

extension HostSetting: CKRecordRecoverable {
}
