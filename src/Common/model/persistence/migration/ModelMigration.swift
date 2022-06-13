//
//  ModelMigration.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 12.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CoreData

class ModelMigration {
	static let migratedToCoreData = "migratedToCoreData"
	
	class func migrateToCoreData() {
		let defaults = UserDefaults.standard
		if !defaults.bool(forKey: migratedToCoreData) {
			let persistence = SQLitePersistence()
			PersistenceHelper.createAll(hosts: persistence.all())
			defaults.set(true, forKey: migratedToCoreData)
		}
	}
}
