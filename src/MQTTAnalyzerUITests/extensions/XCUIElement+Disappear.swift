//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

extension XCUIElement {
	func awaitAppear() {
		XCTAssertTrue(waitForExistence(timeout: 4))
	}
	
	func awaitDisappear(element: XCUIElement) {
		expectation(for: NSPredicate(format: "exists == 0"),
					evaluatedWith: element,
					handler: nil)
		waitForExpectations(timeout: 4, handler: nil)
		
		XCTAssertFalse(element.exists)
	}
}
