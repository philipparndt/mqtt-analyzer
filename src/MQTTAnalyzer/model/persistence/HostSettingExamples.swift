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
		let example2 = HostSetting()
		example2.id = "example.test.mosquitto.org.2"
		example2.alias = "Revspace sensors"
		example2.authType = AuthenticationType.NONE
		example2.hostname = "test.mosquitto.org"
		example2.username = ""
		example2.password = ""
		example2.port = 1883
		example2.qos = 0
		example2.topic = "revspace/sensors/#"
		
		let example3 = HostSetting()
		example3.id = "example.test.mosquitto.org.4"
		example3.alias = "mqtt-analyzer mosquitto example"
		example3.authType = AuthenticationType.NONE
		example3.hostname = "test.mosquitto.org"
		example3.username = ""
		example3.password = ""
		example3.port = 1883
		example3.qos = 0
		example3.topic = "de/rnd7/mqtt-analyzer/#"
		
		createIfNotPresent(setting: example2, realm: realm)
		createIfNotPresent(setting: example3, realm: realm)
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
