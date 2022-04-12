//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class SubscriptionTests: AbstractUITests {
	func testSubscribeToSYS() {
		let brokers = Brokers(app: app)
		
		let alias = "Example"
		app.launch()

		brokers.startEdit(alias: alias)
		brokers.addSubscriptionToCurrentBroker(topic: "$SYS/#")
		brokers.deleteSubscriptionFromCurrentBroker(topic: "#")
		brokers.save()
		
		brokers.start(alias: alias)

		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "$SYS")
	}
}
