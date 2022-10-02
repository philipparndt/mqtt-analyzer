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
		
		let controller = PersistenceController.shared
		let container = controller.container
		
		let existing = PersistenceHelper.loadAllExistingIDs(context: container.viewContext)
		if existing.isEmpty {
			PersistenceHelper.createAll(hosts: [
				example1(),
				example2()
			])
		}
		
		setWritten()
	}
		
	class func create(alias: String, hostname: String, limitTopic: Int = 0, subscriptions: [TopicSubscription]) -> SQLiteBrokerSetting {
		return SQLiteBrokerSetting(
			id: UUID().uuidString,
			alias: alias,
			hostname: hostname,
			port: 1883,
			subscriptions: SubscriptionValueTransformer.encode(subscriptions: subscriptions),
			protocolMethod: Int(ConnectionMethod.mqtt),
			
			basePath: "",
			ssl: false,
			untrustedSSL: false,
			protocolVersion: 0,
			authType: 0,
			
			username: "",
			password: "",
			certificates: CertificateValueTransformer.encode(certificates: []),
			certClientKeyPassword: "",
			clientID: "",
			limitTopic: limitTopic,
			limitMessagesBatch: 1000,
			deleted: false
		)
	}
	
	class func example1() -> SQLiteBrokerSetting {
		return create(
			alias: "Example: Revspace sensors",
			hostname: "test.mosquitto.org",
			limitTopic: 400,
			subscriptions: [
				TopicSubscription(topic: "revspace/sensors/#", qos: 0)
		 ])
	}
	
	class func example2() -> SQLiteBrokerSetting {
		return create(
			alias: "Example: MQTTAnalyzer Mosquitto",
			hostname: "test.mosquitto.org",
			subscriptions: [
				TopicSubscription(topic: "de/rnd7/mqtt-analyzer/#", qos: 0),
				TopicSubscription(topic: "$SYS/#", qos: 0)
			]
		)
	}
	
	class func exampleRnd7() -> SQLiteBrokerSetting {
		return create(
			alias: "Example",
			hostname: "test.mqtt.rnd7.de",
			subscriptions: [
				TopicSubscription(topic: "#", qos: 0)
			]
		)
	}
	
	class func exampleLocalhost() -> SQLiteBrokerSetting {
		return create(
			alias: "localhost",
			hostname: "localhost",
			subscriptions: [
				TopicSubscription(topic: "#", qos: 0)
			]
		)
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
