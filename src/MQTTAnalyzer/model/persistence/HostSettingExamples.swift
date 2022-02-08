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
		if isWritten() {
			return
		}
		
		if !realm.objects(HostSetting.self).isEmpty {
			// the user defaults store was introduced in a later version
			setWritten()
			return
		}

		createIfNotPresent(setting: RealmPresistenceTransformer.transform(example1()), realm: realm)
		createIfNotPresent(setting: RealmPresistenceTransformer.transform(example2()), realm: realm)
		
		setWritten()
	}
	
	class func example1() -> Host {
		let result = Host()
		result.alias = "Revspace sensors"
		result.hostname = "test.mosquitto.org"
		result.limitTopic = 400
		result.subscriptions = [TopicSubscription(topic: "revspace/sensors/#", qos: 0)]
		return result
	}
	
	class func example2() -> Host {
		let result = Host()
		result.alias = "mqtt-analyzer mosquitto example"
		result.hostname = "test.mosquitto.org"
		result.subscriptions = [
			TopicSubscription(topic: "de/rnd7/mqtt-analyzer/#", qos: 0),
			TopicSubscription(topic: "$SYS/#", qos: 0)
		]
		return result
	}
	
	class func exampleLocalhost() -> Host {
		let result = Host()
		result.alias = "Example"
		result.hostname = "localhost"
		result.limitTopic = 400
		result.subscriptions = [TopicSubscription(topic: "#", qos: 0)]
		return result
	}
	
	private class func createIfNotPresent(setting: HostSetting, realm: Realm) {
		do {
			try realm.write {
				realm.add(setting)
			}
		}
		catch {
			NSLog("Error writing example data: \(error.localizedDescription)")
		}
	}
	
	private class func isWritten() -> Bool {
		let defaults = UserDefaults.standard
		return defaults.bool(forKey: "HostSettingExamplesWritten")
	}
	
	private class func setWritten() {
		let defaults = UserDefaults.standard
		defaults.set(true, forKey: "HostSettingExamplesWritten")
	}
}
