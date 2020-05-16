//
//  DataMigration.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-19.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream

class DataMigration {
	
	class func initMigration(syncEngine: SyncEngine?) {
		let configuration = Realm.Configuration(
			schemaVersion: 20,
			migrationBlock: { migration, oldSchemaVersion in
				DataMigrationLimits.migrate(oldSchemaVersion, migration)
				DataMigrationAuth.migrate(oldSchemaVersion, migration)
				DataMigrationClientImpl.migrate(oldSchemaVersion, migration)
				DataMigrationMultipleTopics.migrate(oldSchemaVersion, migration)
				DataMigrationEmptyTopic.migrate(oldSchemaVersion, migration)
				
				DispatchQueue.global(qos: .background).async {
					syncEngine?.pushAll()
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
