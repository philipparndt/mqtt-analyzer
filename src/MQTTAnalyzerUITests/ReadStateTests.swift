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
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		
		let nav = Navigation(app: app, alias: alias)
		let home = nav.getReadMarker(topic: "home")
		let hue = nav.getReadMarker(topic: "hue")
		awaitAppear(element: home)
		awaitAppear(element: hue)

		nav.navigate(to: "hue/light")
		let office = nav.getReadMarker(topic: "hue/light/office")
		let kitchen = nav.getReadMarker(topic: "hue/light/office")
		
		XCTAssertTrue(office.firstMatch.exists)
		XCTAssertTrue(kitchen.firstMatch.exists)
		
		MessageTopicUtils.markAllAsRead(app: app)

		awaitDisappear(element: office)
		awaitDisappear(element: kitchen)

		nav.navigate(to: "hue")
		let light = nav.getReadMarker(topic: "hue/light")
		XCTAssertFalse(light.exists)
		
		nav.navigate(to: "")
		XCTAssertTrue(home.exists)
		XCTAssertFalse(hue.exists)
	}
	
	func testClear() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		
		let nav = Navigation(app: app, alias: alias)
		let homeFolder = nav.folderCell(topic: "home")
		awaitAppear(element: homeFolder.staticTexts["7/7"])

		nav.navigate(to: "home")
		MessageTopicUtils.clearAll(app: app)
		
		nav.navigate(to: "")
		let home = nav.getReadMarker(topic: "home")
		XCTAssertTrue(homeFolder.staticTexts["0/0"].exists)
			XCTAssertFalse(home.exists)
	}
}
