//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class ReadStateTests: AbstractUITests {

	func testMarkRead() {
		let brokers = Brokers(app: app)

		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.id()

		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()

		brokers.start(alias: alias)
		examples.publish(prefix: id)

		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "\(id)")
		let dishwasher = nav.getReadMarker(topic: "\(id)dishwasher")
		let light = nav.getReadMarker(topic: "\(id)light")
		awaitAppear(element: dishwasher)
		awaitAppear(element: light)

		nav.navigate(to: "\(id)light")
		let office = nav.getReadMarker(topic: "\(id)light/office")
		let kitchen = nav.getReadMarker(topic: "\(id)light/kitchen")

		XCTAssertTrue(office.firstMatch.exists, "Expected office to be there")
		XCTAssertTrue(kitchen.firstMatch.exists, "Expected kitchen to be there")

		MessageTopicUtils.markAllAsRead(app: app)

		awaitDisappear(element: office)
		awaitDisappear(element: kitchen)

		nav.navigate(to: "\(id)")
		XCTAssertTrue(dishwasher.exists, "Expected dishwasher to be there")
		XCTAssertFalse(light.exists, "Expected light to be not there")
	}

	func testClear() {
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
		let dishwasherFolder = nav.folderCell(topic: "\(id)dishwasher")
		awaitAppear(element: dishwasherFolder.staticTexts["2/2"])

		nav.navigate(to: "\(id)dishwasher")
		MessageTopicUtils.clearAll(app: app)

		nav.navigate(to: id)
		let dishwasher = nav.getReadMarker(topic: "\(id)dishwasher")
		XCTAssertTrue(dishwasherFolder.staticTexts["0/0"].exists, "Expected 0/0 to be there")
		XCTAssertFalse(dishwasher.exists, "Expected brokerCell dishwasher to be not there")
	}
}
