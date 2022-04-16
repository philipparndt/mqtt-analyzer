//
//  XCTestCase+Disappear.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
	
	func awaitAppear(element: XCUIElement) {
		XCTAssertTrue(element.waitForExistence(timeout: 4), "Expected element to appear")
	}
	
	func awaitDisappear(element: XCUIElement) {
		expectation(for: NSPredicate(format: "exists == 0"),
					evaluatedWith: element,
					handler: nil)
		waitForExpectations(timeout: 4, handler: nil)
		
		XCTAssertFalse(element.exists, "Expected element to disappear")
	}
}
