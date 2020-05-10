//
//  HostSettingExamples.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-23.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

class HostSettingExamples {
	class func inititalize(realm: Realm) {
		let example1 = HostSetting()
		example1.id = "example.test.mosquitto.org.2"
		example1.alias = "Revspace sensors"
		example1.hostname = "test.mosquitto.org"
		example1.subscriptions = HostsModelPersistence.encode(subscriptions: [
			TopicSubscription(topic: "revspace/sensors/#", qos: 0)
		])
		
		let example2 = HostSetting()
		example2.id = "example.test.mosquitto.org.4"
		example2.alias = "mqtt-analyzer mosquitto example"
		example2.hostname = "test.mosquitto.org"
		example2.subscriptions = HostsModelPersistence.encode(subscriptions: [
			TopicSubscription(topic: "de/rnd7/mqtt-analyzer/#", qos: 0),
			TopicSubscription(topic: "$SYS/#", qos: 0)
		])
		
		createIfNotPresent(setting: example1, realm: realm)
		createIfNotPresent(setting: example2, realm: realm)
	}
	
	private class func createIfNotPresent(setting: HostSetting, realm: Realm) {
		let settings = realm.objects(HostSetting.self)
			 .filter("id = %@", setting.id)
		
		if settings.isEmpty {
			// swiftlint:disable force_try
			try! realm.write {
				realm.add(setting)
			}
		}
	}
}
