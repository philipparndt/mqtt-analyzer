//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class PublishTests: AbstractUITests {
	
	func testPublish() {
		let brokers = Brokers(app: app)
		
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.id()

		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()

		brokers.start(alias: alias)
		examples.publish(prefix: id)

		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: id)
		
		XCTAssertTrue(app.staticTexts["hue"]
						.waitForExistence(timeout: 4))

		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "\(id)topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["Inherited Message Groups"].waitForExistence(timeout: 4))
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4))
	}
	
	func testPublishWhileWait() {
		let brokers = Brokers(app: app)
		
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.id()

		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()

		brokers.start(alias: alias)
		examples.publish(prefix: id)

		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: id)
		
		MessageTopicUtils.clearAll(app: app)
		
		XCTAssertTrue(app.staticTexts["Waiting for messages"].waitForExistence(timeout: 4))
		
		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "\(id)topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["Inherited Message Groups"].waitForExistence(timeout: 4))
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4))
	}
}
