//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension XCUIElement {
	
	func clear() {
		tap()
		
		guard let stringValue = self.value as? String else {
			XCTFail("Tried to clear and enter text into a non string value")
			return
		}

		let lowerRightCorner = self.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
		lowerRightCorner.tap()

		let deleteString = stringValue.map { _ in "\u{8}" }.joined(separator: "")
		self.typeText(deleteString)
	}
	
	func clearAndEnterText(text: String) {
		clear()
		typeText(text)
	}
}
