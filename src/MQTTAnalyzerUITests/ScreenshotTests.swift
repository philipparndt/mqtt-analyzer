//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class ScreenshotTests: AbstractUITests {
	//  ~/Library/Containers/de.rnd7.MQTTAnalyzerUITests.xctrunner/Data/screenshots
	func testFullRoundtripScreenshots() {
		let hostname = "localhost"
		let alias = "Example"
		
		let examples = ExampleMessages(hostname: hostname)
		let brokers = Brokers(app: app)
		
		app.launch()

		snapshot(ScreenshotIds.BROKERS)
		
		let nav = Navigation(app: app, alias: alias)
		
		brokers.delete(alias: alias)
		brokers.confirmDelete()
		
		brokers.create(broker: Broker(alias: alias, hostname: hostname))
		brokers.start(alias: alias)

		examples.publish(prefix: "")

		nav.navigate(to: "home/dishwasher/000123456789")
		nav.openMessageGroup()
		snapshot(ScreenshotIds.JSON_DATA)
		
		nav.navigate(to: "home/dishwasher/000123456789/full")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.JSON_DETAILS)
		
		nav.navigate(to: "hue")
		nav.flatView()
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatView()

		nav.navigate(to: "hue/light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)
		
		nav.publishNew(topic: "hue/light/kitchen/coffee-spot")
	}
}
