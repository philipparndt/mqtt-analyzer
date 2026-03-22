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
		// Use empty prefix for nice-looking screenshots
		let id = ""

		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname, port: port, tls: tls))
		let brokers = Brokers(app: app)

		app.launch()

		let nav = Navigation(app: app, alias: alias)

		// Open the edit dialog to take the CONFIG screenshot
		// The broker is pre-configured via HostSettingExamples.exampleRnd7()
		brokers.startEdit(alias: alias)
		snapshot(ScreenshotIds.CONFIG)
		brokers.save()

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
		examples.publishVacuumMap(prefix: id)

		// Wait for messages to be received before navigating
		let firstTopic = app.descendants(matching: .any)["folder: \(id)dishwasher"].firstMatch
		XCTAssertTrue(firstTopic.waitForExistence(timeout: 15), "Expected topics to appear after publishing")

		// Expand tree nodes to demonstrate tree navigation
		nav.expandTreeNode(topic: "\(id)dishwasher")

		// Wait for children to appear after expansion
		let dishwasherChild = app.descendants(matching: .any)["folder: \(id)dishwasher/000123456789"].firstMatch
		XCTAssertTrue(dishwasherChild.waitForExistence(timeout: 5), "Expected dishwasher/000123456789 to appear after expanding")

		// Also expand the nested topic for a bigger tree
		nav.expandTreeNode(topic: "\(id)dishwasher/000123456789")
		let nestedTopic = app.descendants(matching: .any)["folder: \(id)dishwasher/000123456789/full"].firstMatch
		XCTAssertTrue(nestedTopic.waitForExistence(timeout: 5), "Expected nested topic to appear after expanding")

		// Take screenshot of the tree view with expanded nodes
		snapshot(ScreenshotIds.TREE_VIEW)

		// On iPhone, collapse the tree before navigating
		if !nav.isThreeColumnLayout {
			nav.expandTreeNode(topic: "\(id)dishwasher/000123456789")
			nav.expandTreeNode(topic: "\(id)dishwasher")
		}

		// Navigate to dishwasher JSON data
		nav.navigate(to: "\(id)dishwasher/000123456789")
		nav.openMessageGroup()
		snapshot(ScreenshotIds.JSON_DATA)

		nav.navigate(to: "\(id)dishwasher/000123456789/full")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.JSON_DETAILS)

		// Vacuum map - image view
		nav.navigateToRoot()
		nav.navigate(to: "\(id)vacuum/map")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.IMAGE_VIEW)

		// Switch to Hex tab on the same vacuum map image
		let hexTab = app.buttons["Hex"].firstMatch
		XCTAssertTrue(hexTab.waitForExistence(timeout: 5), "Expected Hex tab to exist")
		hexTab.tap()
		snapshot(ScreenshotIds.BINARY_HEX)

		// Navigate to the light section for flat view
		nav.navigateToRoot()
		nav.navigate(to: "\(id)light")
		nav.flatView(tc: self)
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatViewOff(tc: self)

		nav.navigate(to: "\(id)light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)

		// Long press on coffee-spot to show context menu and open publish dialog with prefilled data
		if nav.isThreeColumnLayout {
			nav.expandTreeNode(topic: "\(id)light/kitchen")

			let coffeeSpot = app.descendants(matching: .any)["folder: \(id)light/kitchen/coffee-spot"].firstMatch
			XCTAssertTrue(coffeeSpot.waitForExistence(timeout: 5), "Expected coffee-spot to appear after expanding")
		}

		nav.publishNew(topic: "\(id)light/kitchen/coffee-spot")

		// Take brokers screenshot at the end when the broker is connected with messages
		nav.navigateToBrokers()
		snapshot(ScreenshotIds.BROKERS)
	}
}
