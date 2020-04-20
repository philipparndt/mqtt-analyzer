//
//  DataMigration.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-19.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

class DataMigration {
	private class func migrateLimits(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 4 {
			migration.enumerateObjects(ofType: HostSetting.className()) { _, newObject in
				if let no = newObject {
					no["limitTopic"] = 250
					no["limitMessagesBatch"] = 1000
				}
			}
		}
	}
	
	// Add support for different auth types
	private class func migrateAuth(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 5 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					let auth = oo["auth"] as? Bool
					if auth ?? false {
						no["authType"] = AuthenticationType.usernamePassword
					}
					else {
						no["authType"] = AuthenticationType.none
					}
				}
			}
		}
	}
	
	// Added support for Cocoamqtt
	private class func migrateClientImpl(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 9 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let authType = oldObject!["authType"] as? Int8,
				   let no = newObject {
					no["clientImplType"] = (authType == AuthenticationType.certificate ? ClientImplType.moscapsule : ClientImplType.cocoamqtt)
				}
			}
		}
	}
	
	class func initMigration() {
		let configuration = Realm.Configuration(
			schemaVersion: 9,
			migrationBlock: { migration, oldSchemaVersion in
				migrateLimits(oldSchemaVersion, migration)
				migrateAuth(oldSchemaVersion, migration)
				migrateClientImpl(oldSchemaVersion, migration)
				
//				Example on how to rename properties:
//				if oldSchemaVersion < n {
//					migration.renameProperty(onType: HostSetting.className(), from: "old", to: "new")
//				}
				
//				Example on how to delete old properties:
//				if oldSchemaVersion < n {
//					// nothing to do (realm will add new properties and delete old)
//				}
			}
		)
		Realm.Configuration.defaultConfiguration = configuration
	}
}
