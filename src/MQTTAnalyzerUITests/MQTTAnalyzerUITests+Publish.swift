//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension MQTTAnalyzerUITests {
	
	func testPublish() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)

		XCTAssertTrue(app.staticTexts["hue"]
						.waitForExistence(timeout: 4))

		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["Inherited Message Groups"].waitForExistence(timeout: 4))
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4))
	}
	
	func testPublishWhileWait() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		
		MessageTopicUtils.clearAll(app: app)
		
		XCTAssertTrue(app.staticTexts["Waiting for messages"].waitForExistence(timeout: 4))
		
		let dialog = PublishDialog(app: app)
		dialog.open()
		dialog.fill(topic: "topic", message: "msg")
		dialog.apply()
		
		XCTAssertTrue(app.staticTexts["Inherited Message Groups"].waitForExistence(timeout: 4))
		XCTAssertTrue(app.staticTexts["msg"].waitForExistence(timeout: 4))
	}
}
