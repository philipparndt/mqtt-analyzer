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
class DataMigrationNavigationMode {
	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 26 {
			migration.enumerateObjects(ofType: HostSetting.className()) { _, newObject in
				if let no = newObject {
					no["maxMessagesOfSubFolders"] = 10
					no["navigationMode"] = NavigationModeType.folders
				}
			}
		}
	}
}
