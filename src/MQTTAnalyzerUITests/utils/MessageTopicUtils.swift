//
//  MessageTopicUtils.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class MessageTopicUtils {
	class func markAllAsRead(app: XCUIApplication) {
		#if os(macOS)
		app.buttons["Mark all as read"].tap()
		#else
		let cell = app.buttons["Filter"]
		XCTAssertTrue(cell.waitForExistence(timeout: 4))
		app.launchMenuAction(on: cell, label: "Mark all as read")
		#endif
	}

	class func clearAll(app: XCUIApplication) {
		#if os(macOS)
		app.buttons["Clear"].tap()
		#else

		let cell = app.buttons["Filter"]
		XCTAssertTrue(cell.waitForExistence(timeout: 4))
		app.launchMenuAction(on: cell, label: "Clear")
		#endif
	}
}
