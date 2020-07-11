//
//  DataMigrationAuth.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// Added support for multiple topics
class DataMigrationMoscapsuleDeprecation {
	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 24 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					if hasProperties(oldObject, properties: "authType") {
						let auth = oo["authType"] as? Int8
						if auth ?? AuthenticationType.none != AuthenticationType.certificate {
							no["clientImplType"] = ClientImplType.cocoamqtt
						}
					}
				}
			}
		}
	}
}
