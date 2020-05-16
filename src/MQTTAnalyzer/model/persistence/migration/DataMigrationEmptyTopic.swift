//
//  MultipleTopics.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// Filter invalid subscriptions from a beta version
class DataMigrationEmptyTopic {

	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 15 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					if hasProperties(oldObject, properties: "subscriptions") {
						if let data = oo.value(forKey: "subscriptions") as? Data {
							let subscriptions = HostsModelPersistence.decode(subscriptions: data)
							no["subscriptions"] = HostsModelPersistence.encode(subscriptions: subscriptions)
						}
					}
				}
			}
		}
	}
}
