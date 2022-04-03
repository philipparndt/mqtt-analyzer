//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension XCUIElement {
	
	func isEmpty() -> Bool {
		guard let stringValue = self.value as? String else {
			XCTFail("Tried to clear and enter text into a non string value")
			return false
		}
		
		if stringValue.isEmpty {
			return true
		}
		
		// workaround for apple bug
		if let placeholderString = self.placeholderValue, placeholderString == stringValue {
			return true
		}
		
		return false
	}
	
	func clear() {
		if alreadyClearStrategy() || clearWithDeleteKeyStrategy() || clearWithSelectAllStrategy() {
			return
		}
		
		XCTFail("Failed to clear text field")
	}
	
	func clearAndEnterText(text: String) {
		clear()
		typeText(text)
	}
}

extension XCUIElement {
	func alreadyClearStrategy() -> Bool {
		return isEmpty()
	}
	
	func clearWithDeleteKeyStrategy() -> Bool {
		guard let stringValue = self.value as? String else {
			XCTFail("Tried to clear and enter text into a non string value")
			return false
		}

		let lowerRightCorner = self.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
		lowerRightCorner.tap()

		let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
		self.typeText(deleteString)
		
		return isEmpty()
	}
	
	func clearWithSelectAllStrategy() -> Bool {
		// Use other strategy
		self.press(forDuration: 1.2)
		AbstractUITests.currentApp.menuItems["Select All"].tap()
		self.typeText(XCUIKeyboardKey.delete.rawValue)
		
		return isEmpty()
	}
}
