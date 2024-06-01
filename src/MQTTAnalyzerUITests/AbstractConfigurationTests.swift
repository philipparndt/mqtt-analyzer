//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class AbstractConfigurationTests: AbstractUITests {
	let hostname = TestServer.getTestServer()

	@MainActor func assertWithBroker(_ broker: Broker, tc: XCTestCase, credentials: Credentials? = nil) {
		let id = Navigation.id()
		let brokers = Brokers(app: app)

		app.launch()
		
		let nav = Navigation(app: app, alias: broker.alias!)
		
		brokers.create(broker: broker, tc: tc)
		brokers.start(alias: broker.alias!, waitConnected: false)
		
		if let credentials = credentials {
			brokers.login(credentials: credentials)
		}
		
		brokers.waitUntilConnected()

		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "\(id)topic", message: "msg")
		dialog.apply()
		
		nav.navigate(to: "\(id)topic")
	}
}
