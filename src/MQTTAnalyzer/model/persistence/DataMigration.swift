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
	
	private class func hasProperties(_ oldObject: DynamicObject?, properties: String...) -> Bool {
		for property in properties {
			if !(oldObject?.objectSchema
			.properties
				.contains(where: { $0.name == property }) ?? false) {
				return false
			}
		}
		
		return true
	}
	
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
					var done = false
					if DataMigration.hasProperties(oldObject, properties: "auth") {
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
	
	// Added support for Cocoamqtt
	private class func migrateClientImpl(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 11 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					if DataMigration.hasProperties(oldObject, properties: "authType") {
						if let authType = oo["authType"] as? Int8 {
							no["clientImplType"] = (authType == AuthenticationType.certificate ? ClientImplType.moscapsule : ClientImplType.cocoamqtt)
						}
					}
				}
			}
		}
	}
	
	// Added support for multiple topics
	private class func migrateMultipleTopics(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 14 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					var done = false
					
					if DataMigration.hasProperties(oldObject, properties: "qos", "topic") {
						if let qos = oo.value(forKey: "qos") as? Int,
							let topic = oo.value(forKey: "topic") as? String {
							no["subscriptions"] = HostsModelPersistence.encode(subscriptions: [
								TopicSubscription(topic: topic, qos: Int8(qos))
							])
							
							done = true
						}
					}
					
					if !done {
						no["subscriptions"] = HostsModelPersistence.encode(subscriptions: [
							TopicSubscription(topic: "#", qos: 0)
						])
					}
				}
			}
		}
	}
	
	class func initMigration() {
		let configuration = Realm.Configuration(
			schemaVersion: 14,
			migrationBlock: { migration, oldSchemaVersion in
				migrateLimits(oldSchemaVersion, migration)
				migrateAuth(oldSchemaVersion, migration)
				migrateClientImpl(oldSchemaVersion, migration)
				migrateMultipleTopics(oldSchemaVersion, migration)
				
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
