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
		let port = TestServer.getTestPort()
		let tls = TestServer.isTLS()
		let alias = "Example"
		// Use empty prefix for nice-looking screenshots (topics start with "home/", "hue/", etc.)
		let id = ""

		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname, port: port, tls: tls))
		let brokers = Brokers(app: app)

		app.launch()

		let nav = Navigation(app: app, alias: alias)

		brokers.delete(alias: alias)
		brokers.confirmDelete()

		brokers.create(broker: Broker(alias: alias, hostname: hostname, port: port, tls: tls), tc: self)

		// Take diagnostics screenshot before connecting
		brokers.openDiagnostics(alias: alias)

		// Wait for all diagnostic checks to complete
		let anyResult = [
			app.staticTexts["All checks passed"].firstMatch,
			app.staticTexts["Issues detected"].firstMatch,
			app.staticTexts["Some warnings found"].firstMatch
		]
		for element in anyResult where element.waitForExistence(timeout: 30) {
			break
		}

		snapshot(ScreenshotIds.DIAGNOSTICS)

		// Close diagnostics sheet
		app.buttons["Close"].tap()

		brokers.start(alias: alias)

		examples.publish(prefix: id)
		examples.publishBinary(prefix: id)

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

		// Binary/Image screenshots
		nav.navigateToRoot()
		nav.navigate(to: "\(id)test/binary/logo")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.IMAGE_VIEW)

		nav.navigateToRoot()
		nav.navigate(to: "\(id)test/binary/raw")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.BINARY_HEX)

		// Navigate to the hue section
		nav.navigateToRoot()
		nav.navigate(to: "\(id)hue")
		nav.flatView(tc: self)
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatViewOff(tc: self)

		nav.navigate(to: "\(id)hue/light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)

		// Long press on coffee-spot to show context menu and open publish dialog with prefilled data
		// On iPad, we need to expand the tree to reveal coffee-spot
		if nav.isThreeColumnLayout {
			nav.expandTreeNode(topic: "\(id)hue/light/kitchen")

			let coffeeSpot = app.descendants(matching: .any)["folder: \(id)hue/light/kitchen/coffee-spot"].firstMatch
			XCTAssertTrue(coffeeSpot.waitForExistence(timeout: 5), "Expected coffee-spot to appear after expanding")
		}

		nav.publishNew(topic: "\(id)hue/light/kitchen/coffee-spot")

		// Take brokers screenshot at the end when the broker is connected with messages
		nav.navigateToBrokers()
		snapshot(ScreenshotIds.BROKERS)
	}
}
