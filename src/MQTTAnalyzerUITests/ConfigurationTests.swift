//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import RealmSwift

class ConfigurationTests: AbstractUITests {
	let hostname = "localhost"

	func assertWithBroker(_ broker: Broker, credentials: Credentials? = nil) {
		let id = Navigation.id()
		let examples = ExampleMessages(broker: broker, credentials: credentials)
		let brokers = Brokers(app: app)

		app.launch()
		
		let nav = Navigation(app: app, alias: broker.alias!)
		
		brokers.create(broker: broker)
		brokers.start(alias: broker.alias!, waitConnected: false)
		
		if let credentials = credentials {
			brokers.login(credentials: credentials)
		}
		
		brokers.waitUntilConnected()
		
		examples.publish(prefix: id)

		nav.navigate(to: "\(id)home")
		
		let smallId = Navigation.idSmall(suffix: "")
		
		let publish = PublishDialog(app: app)
		publish.open()
		publish.fill(topic: "\(id)home/\(smallId)", message: id)
		publish.apply()
		
		nav.navigate(to: "\(id)home/\(smallId)")
	}
	
	func testMQTTNoAuth() {
		assertWithBroker(
			Broker(
				alias: "1883",
				hostname: hostname,
				port: 1883
			)
		)
	}
	
	func testMQTTPersistedAuth() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin",
				password: "password"
			)
		)
	}
	
	func testMQTTPersistedUsername() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin"
			),
			credentials: Credentials(username: nil, password: "password")
		)
	}
	
	func testWebSocket() {
		assertWithBroker(
			Broker(
				alias: "WebSocket",
				hostname: hostname,
				port: 9001,
				connectionProtocol: .websocket
			)
		)
	}
	
	func testWebSocketPersistedAuth() {
		assertWithBroker(
			Broker(
				alias: "9002",
				hostname: hostname,
				port: 9002,
				connectionProtocol: .websocket,
				authType: .userPassword,
				username: "admin",
				password: "password"
			)
		)
	}
	
	func testWebSocketPersistedUsername() {
		assertWithBroker(
			Broker(
				alias: "9002",
				hostname: hostname,
				port: 9002,
				connectionProtocol: .websocket,
				authType: .userPassword,
				username: "admin"
			),
			credentials: Credentials(username: nil, password: "password")
		)
	}
}
