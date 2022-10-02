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
						.waitForExistence(timeout: 4), "Expected hue to be there")

		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "\(id)topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["INHERITED MESSAGE GROUPS"].waitForExistence(timeout: 4), "Expected Inherited Message Groups to be there")
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4), "Expected msg to be there")
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
		
		XCTAssertTrue(app.staticTexts["Waiting for messages"].waitForExistence(timeout: 4), "Expected waiting for messages to be there")
		
		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "\(id)topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["INHERITED MESSAGE GROUPS"].waitForExistence(timeout: 4), "Expected inherited messages groups to be there")
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4), "Expected msg to be there")
	}
}
