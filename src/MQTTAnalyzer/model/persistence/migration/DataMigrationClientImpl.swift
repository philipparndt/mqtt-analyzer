//
//  DataMigrationClientImpl.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// Added support for multiple topics
class DataMigrationClientImpl {

	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 11 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					if hasProperties(oldObject, properties: "authType") {
						if let authType = oo["authType"] as? Int8 {
							no["clientImplType"] = (authType == AuthenticationType.certificate ? ClientImplType.moscapsule : ClientImplType.cocoamqtt)
						}
					}
				}
			}
		}
	}
}
