//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension XCUIElement {

	/// Checks if the text field is effectively empty (either actually empty or showing placeholder)
	func isEmpty() -> Bool {
		guard let stringValue = self.value as? String else {
			return true
		}

		if stringValue.isEmpty {
			return true
		}

		// When a text field is empty, iOS may return the placeholder as the value
		if let placeholderString = self.placeholderValue, placeholderString == stringValue {
			return true
		}

		return false
	}

	/// Clears the text in a text field using select-all and delete
	func clear() {
		guard self.exists, self.isHittable else {
			return
		}

		// Skip if already empty
		if isEmpty() {
			self.tap()
			return
		}

		// Tap to focus the field
		self.tap()

		// Triple-tap to select all text (works reliably in iOS 15+)
		self.tap(withNumberOfTaps: 3, numberOfTouches: 1)

		// Delete the selected text
		self.typeText(XCUIKeyboardKey.delete.rawValue)
	}

	/// Clears the text field and enters new text
	func clearAndEnterText(text: String) {
		clear()
		typeText(text)
	}

	/// Only clears and enters text if the current value differs from the desired text
	func enterTextIfNotAlreadySame(text: String) {
		guard let stringValue = self.value as? String else {
			clearAndEnterText(text: text)
			return
		}

		if stringValue != text {
			clearAndEnterText(text: text)
		}
	}
}
