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
	@MainActor func testFullRoundtripScreenshots() {
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.idSmall()
		
		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		let brokers = Brokers(app: app)
		
		app.launch()

		snapshot(ScreenshotIds.BROKERS)
		
		let nav = Navigation(app: app, alias: alias)
		
		brokers.delete(alias: alias)
		brokers.confirmDelete()
		
		brokers.create(broker: Broker(alias: alias, hostname: hostname), tc: self)
		brokers.start(alias: alias)

		examples.publish(prefix: id)

		nav.navigate(to: "\(id)home/dishwasher/000123456789")
		nav.openMessageGroup()
		snapshot(ScreenshotIds.JSON_DATA)
		
		nav.navigate(to: "\(id)home/dishwasher/000123456789/full")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.JSON_DETAILS)
		
		nav.navigate(to: "\(id)hue")
		nav.flatView(tc: self)
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatViewOff(tc: self)

		nav.navigate(to: "\(id)hue/light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)
		
		nav.publishNew(topic: "\(id)hue/light/kitchen/coffee-spot")
	}
}
