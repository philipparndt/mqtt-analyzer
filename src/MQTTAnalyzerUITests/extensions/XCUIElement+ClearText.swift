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
	
	func isPlaceholderEqValue() -> Bool {
		guard let stringValue = self.value as? String else {
			XCTFail("Tried to clear and enter text into a non string value")
			return false
		}
		
		if stringValue.isEmpty {
			return false
		}
		
		// workaround for apple bug
		if let placeholderString = self.placeholderValue, placeholderString == stringValue {
			return true
		}
		
		return false
	}
	
	func clear() {
		#if targetEnvironment(macCatalyst)
		self.tap()
		#endif
		
		if fastClearStrategy() || clearWithDeleteKeyStrategy() || clearWithSelectAllStrategy() {
			return
		}
		
		XCTFail("Failed to clear text field")
	}
	
	func clearAndEnterText(text: String) {
		clear()
		typeText(text)
	}
	
	func enterTextIfNotAlreadySame(text: String) {
		guard let stringValue = self.value as? String else {
			XCTFail("Tried to clear and enter text into a non string value")
			return
		}
		
		if stringValue != text {
			clearAndEnterText(text: text)
		}
	}
}

extension XCUIElement {
	/*
	 Try a fast clear by typing a single character, verify that it is the
	 single character and delete it again.
	 
	 This is necessary as we cannot distinct between a placeholder value
	 and the same value entered.
	 */
	func fastClearStrategy() -> Bool {
		if isPlaceholderEqValue() {
			self.typeText(".")
			
			guard let stringValue = self.value as? String else {
				XCTFail("Tried to clear and enter text into a non string value")
				return false
			}
			
			if stringValue == "." {
				self.typeText(XCUIKeyboardKey.delete.rawValue)
			}
			return isEmpty()
		}
		
		return false
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

		#if !targetEnvironment(macCatalyst)
		let lowerRightCorner = self.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
		lowerRightCorner.tap()
		#endif
		
		let sometimesCharactersMissing = 5
		let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count + sometimesCharactersMissing)
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
