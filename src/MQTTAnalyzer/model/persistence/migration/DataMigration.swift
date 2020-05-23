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
	
	/// **Rename properties**
	/// migration.renameProperty(onType: HostSetting.className(), from: "old", to: "new")
	///
	/// **Add and delete properties**
	/// realm will add new properties and delete old
	///
	class func initMigration(afterMigration: @escaping () -> Void) {
		let configuration = Realm.Configuration(
			schemaVersion: 21,
			migrationBlock: { migration, oldSchemaVersion in
				DataMigrationLimits.migrate(oldSchemaVersion, migration)
				DataMigrationAuth.migrate(oldSchemaVersion, migration)
				DataMigrationClientImpl.migrate(oldSchemaVersion, migration)
				DataMigrationMultipleTopics.migrate(oldSchemaVersion, migration)
				DataMigrationEmptyTopic.migrate(oldSchemaVersion, migration)
				DataMigrationCertificateFiles.migrate(oldSchemaVersion, migration)
				
				DispatchQueue.global(qos: .background).async {
					afterMigration()
				}
			}
		)
		Realm.Configuration.defaultConfiguration = configuration
	}
}
