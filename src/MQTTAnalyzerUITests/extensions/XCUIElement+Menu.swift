//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension XCUIApplication {
	func openMenu(on element: XCUIElement) {
		#if os(macOS)
		element.rightClick()
		#else
		element.press(forDuration: 1)
		#endif
	}

	func tapMenuItem(label: String) {
		#if os(macOS)
		let item = menuItems[label]
		if item.waitForExistence(timeout: 3) {
			item.tap()
		} else {
			// Fallback: try as button (some SwiftUI context menus use buttons)
			buttons[label].tap()
		}
		#else
		buttons[label].tap()
		#endif
	}

	func tapMenuItem(identifier: String) {
		#if os(macOS)
		let item = menuItems[identifier]
		if item.waitForExistence(timeout: 3) {
			item.tap()
		} else {
			buttons[identifier].tap()
		}
		#else
		buttons[identifier].tap()
		#endif
	}

	func launchMenuAction(on element: XCUIElement, label: String) {
		openMenu(on: element)
		tapMenuItem(label: label)
	}

	func launchMenuAction(on element: XCUIElement, identifier: String) {
		openMenu(on: element)
		tapMenuItem(identifier: identifier)
	}

	/// Finds an element by accessibility identifier, handling macOS OutlineView
	/// identifier concatenation (e.g. "folder: X-folder: X-folder: X" instead of "folder: X")
	func elementContainingIdentifier(_ identifier: String) -> XCUIElement {
		#if os(macOS)
		return descendants(matching: .any).matching(
			NSPredicate(format: "identifier CONTAINS %@", identifier)
		).firstMatch
		#else
		return descendants(matching: .any)[identifier].firstMatch
		#endif
	}

}
