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

class HostSetting: Object {
	@objc dynamic var id = NSUUID().uuidString
	@objc dynamic var alias = ""
	@objc dynamic var hostname = ""
	@objc dynamic var port: Int32 = 1883

	@objc dynamic var subscriptions: Data = Data()

	@objc dynamic var protocolMethod: Int8 = ConnectionMethod.mqtt
	@objc dynamic var basePath: String = ""
	@objc dynamic var ssl: Bool = false
	@objc dynamic var untrustedSSL: Bool = false
	
	@objc dynamic var clientImplType: Int8 = ClientImplType.cocoamqtt
	
	@objc dynamic var authType: Int8 = AuthenticationType.none
	@objc dynamic var username: String = ""
	@objc dynamic var password: String = ""
	
	@objc dynamic var certificates: Data = Data()
	@objc dynamic var certClientKeyPassword: String = ""

	@objc dynamic var clientID = Host.randomClientId()

	@objc dynamic var limitTopic = 250
	@objc dynamic var limitMessagesBatch = 1000
	
	@objc dynamic var isDeleted = false
	
	override class func primaryKey() -> String? {
		return "id"
	}
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
