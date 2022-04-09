//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class ConfigurationTests: AbstractUITests {
	let hostname = "localhost"

	func assertWithBroker(id: String, alias: String, broker: Broker) {
		let examples = ExampleMessages(hostname: hostname)
		let brokers = Brokers(app: app)

		app.launch()
		
		let nav = Navigation(app: app, alias: alias)
		
		brokers.create(broker: broker)
		brokers.start(alias: alias)

		examples.publish(prefix: id)

		nav.navigate(to: "\(id)home")
		
		let publish = PublishDialog(app: app)
		publish.open()
		publish.fill(topic: "\(id)home/\(id)", message: id)
		publish.apply()
		
		nav.navigate(to: "\(id)home/\(id)")
	}
	
	func testWebSocket() {
		let alias = "WebSocket"
		let id = Navigation.id()
		
		assertWithBroker(
			id: id,
			alias: alias,
			broker: Broker(
				alias: alias,
				hostname: hostname,
				port: "9001",
				connectionProtocol: .websocket
			)
		)
	}
}
