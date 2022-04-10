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
		let home = nav.getReadMarker(topic: "\(id)home")
		let hue = nav.getReadMarker(topic: "\(id)hue")
		awaitAppear(element: home)
		awaitAppear(element: hue)

		nav.navigate(to: "\(id)hue/light")
		let office = nav.getReadMarker(topic: "\(id)hue/light/office")
		let kitchen = nav.getReadMarker(topic: "\(id)hue/light/office")
		
		XCTAssertTrue(office.firstMatch.exists)
		XCTAssertTrue(kitchen.firstMatch.exists)
		
		MessageTopicUtils.markAllAsRead(app: app)

		awaitDisappear(element: office)
		awaitDisappear(element: kitchen)

		nav.navigate(to: "\(id)hue")
		let light = nav.getReadMarker(topic: "\(id)hue/light")
		XCTAssertFalse(light.exists)
		
		nav.navigate(to: "\(id)")
		XCTAssertTrue(home.exists)
		XCTAssertFalse(hue.exists)
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
		let homeFolder = nav.folderCell(topic: "\(id)home")
		awaitAppear(element: homeFolder.staticTexts["7/7"])

		nav.navigate(to: "\(id)home")
		MessageTopicUtils.clearAll(app: app)
		
		nav.navigate(to: id)
		let home = nav.getReadMarker(topic: "\(id)home")
		XCTAssertTrue(homeFolder.staticTexts["0/0"].exists)
			XCTAssertFalse(home.exists)
	}
}
