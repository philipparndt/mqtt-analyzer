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
		// Use empty prefix for nice-looking screenshots (topics start with "home/", "hue/", etc.)
		let id = ""

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

		// Wait for messages to be received before navigating
		// The first folder cell should appear once messages arrive
		let firstTopic = app.descendants(matching: .any)["folder: \(id)home"].firstMatch
		XCTAssertTrue(firstTopic.waitForExistence(timeout: 15), "Expected topics to appear after publishing")

		// Expand tree nodes to demonstrate tree navigation
		nav.expandTreeNode(topic: "\(id)home")

		// Wait for children to appear after expansion
		let dishwasherTopic = app.descendants(matching: .any)["folder: \(id)home/dishwasher"].firstMatch
		XCTAssertTrue(dishwasherTopic.waitForExistence(timeout: 5), "Expected home/dishwasher to appear after expanding")

		// Also expand dishwasher for a bigger tree
		nav.expandTreeNode(topic: "\(id)home/dishwasher")
		let nestedTopic = app.descendants(matching: .any)["folder: \(id)home/dishwasher/000123456789"].firstMatch
		XCTAssertTrue(nestedTopic.waitForExistence(timeout: 5), "Expected nested topic to appear after expanding")

		// Take screenshot of the tree view with expanded nodes
		snapshot(ScreenshotIds.TREE_VIEW)

		// On iPhone, collapse the tree before navigating (tap chevrons again)
		// On iPad, the tree stays visible in the sidebar, no need to collapse
		if !nav.isThreeColumnLayout {
			nav.expandTreeNode(topic: "\(id)home/dishwasher")
			nav.expandTreeNode(topic: "\(id)home")
		}

		// Now navigate normally using folder-by-folder approach
		nav.navigate(to: "\(id)home/dishwasher/000123456789")
		nav.openMessageGroup()
		snapshot(ScreenshotIds.JSON_DATA)

		nav.navigate(to: "\(id)home/dishwasher/000123456789/full")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.JSON_DETAILS)

		nav.navigateToRoot()
		nav.navigate(to: "\(id)hue")
		nav.flatView(tc: self)
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatViewOff(tc: self)

		nav.navigate(to: "\(id)hue/light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)

		// Expand tree to reveal coffee-spot (needed for iPad tree view)
		if nav.isThreeColumnLayout {
			let coffeeSpot = app.descendants(matching: .any)["folder: \(id)hue/light/kitchen/coffee-spot"].firstMatch
			XCTAssertTrue(coffeeSpot.waitForExistence(timeout: 5), "Expected coffee-spot to appear after expanding")
		}

		// Long press on coffee-spot to show context menu and open publish dialog with prefilled data
		nav.publishNew(topic: "\(id)hue/light/kitchen/coffee-spot")
	}
}
