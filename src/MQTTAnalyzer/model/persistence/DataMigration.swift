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
	class func initMigration() {
		let configuration = Realm.Configuration(
			schemaVersion: 2,
			migrationBlock: { migration, oldSchemaVersion in
				if oldSchemaVersion < 2 {
					migration.enumerateObjects(ofType: HostSetting.className()) { _, newObject in
						newObject!["clientID"] = Host.randomClientId()
					}
				}

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
