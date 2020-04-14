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
	static let NONE: Int8 = 0
	static let USERNAME_PASSWORD: Int8 = 1
	static let CERTIFICATE: Int8 = 2
}

struct ConnectionMethod {
	static let MQTT: Int8 = 0
	static let WEBSOCKET: Int8 = 1
}

struct ClientImplType {
	static let MOSCAPSULE: Int8 = 0
	static let COCOAMQTT: Int8 = 1
}

class HostSetting: Object {
	@objc dynamic var id = NSUUID().uuidString
	@objc dynamic var alias = ""
	@objc dynamic var hostname = ""
	@objc dynamic var port: Int32 = 1883
	@objc dynamic var topic: String = "#"
	@objc dynamic var qos: Int = 0

	@objc dynamic var protocolMethod: Int8 = ConnectionMethod.MQTT
	@objc dynamic var basePath: String = ""
	
	@objc dynamic var clientImplType: Int8 = ClientImplType.MOSCAPSULE
	
	@objc dynamic var authType: Int8 = AuthenticationType.NONE
	@objc dynamic var username: String = ""
	@objc dynamic var password: String = ""
	
	@objc dynamic var certServerCA: String = ""
	@objc dynamic var certClient: String = ""
	@objc dynamic var certClientKey: String = ""
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
