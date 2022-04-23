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
class DataMigrationAuth {
	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 5 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					var done = false
					if hasProperties(oldObject, properties: "auth") {
						let auth = oo["auth"] as? Bool
						if auth ?? false {
							no["authType"] = AuthenticationType.usernamePassword
							done = true
						}
					}
					
					if !done {
						no["authType"] = AuthenticationType.none
					}
				}
			}
		}
	}
}
