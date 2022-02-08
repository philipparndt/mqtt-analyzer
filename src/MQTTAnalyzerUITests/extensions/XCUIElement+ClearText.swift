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
		doubleTap()
	}

	func clearAndEnterText(text: String) {
		clear()
		typeText(text)
	}
}
