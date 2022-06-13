//
//  HostSettingExamples.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-23.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class HostSettingExamples {
	class func inititalize() {
		if isWritten() {
			return
		}
		
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
	
	class func exampleRnd7() -> Host {
		let result = Host()
		result.alias = "Example"
		result.hostname = "test.mqtt.rnd7.de"
		result.limitTopic = 0
		result.subscriptions = [TopicSubscription(topic: "#", qos: 0)]
		return result
	}
	
	class func exampleLocalhost() -> Host {
		let result = Host()
		result.alias = "localhost"
		result.hostname = "localhost"
		result.limitTopic = 0
		result.subscriptions = [TopicSubscription(topic: "#", qos: 0)]
		return result
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
