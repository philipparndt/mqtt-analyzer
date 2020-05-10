//
//  MultipleTopics.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// Added support for multiple topics
class DataMigrationMultipleTopics {

	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 14 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					if !migrateTopic(oldObject, oo, no) {
						initDefault(no)
					}
				}
			}
		}
	}

	private class func migrateTopic(_ oldObject: MigrationObject?, _ oo: MigrationObject, _ no: MigrationObject) -> Bool {
		if hasProperties(oldObject, properties: "qos", "topic") {
			if let qos = oo.value(forKey: "qos") as? Int,
				let topic = oo.value(forKey: "topic") as? String {
				no["subscriptions"] = HostsModelPersistence.encode(subscriptions: [
					TopicSubscription(topic: topic, qos: qos)
				])
				
				return true
			}
		}
		
		return false
	}
	
	private class func initDefault(_ no: MigrationObject) {
		no["subscriptions"] = HostsModelPersistence.encode(subscriptions: [
			TopicSubscription(topic: "#", qos: 0)
		])
	}
	
}
