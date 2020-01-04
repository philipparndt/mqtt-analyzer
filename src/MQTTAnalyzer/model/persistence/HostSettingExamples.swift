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
		example1.id = "example.test.mosquitto.org.1"
		example1.alias = "Water levels"
		example1.auth = false
		example1.hostname = "test.mosquitto.org"
		example1.username = ""
		example1.password = ""
		example1.port = 1883
		example1.qos = 0
		example1.topic = "de.wsv/#"
		
		let example2 = HostSetting()
		example2.id = "example.test.mosquitto.org.2"
		example2.alias = "Revspace sensors"
		example2.auth = false
		example2.hostname = "test.mosquitto.org"
		example2.username = ""
		example2.password = ""
		example2.port = 1883
		example2.qos = 0
		example2.topic = "revspace/sensors/#"
		
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
