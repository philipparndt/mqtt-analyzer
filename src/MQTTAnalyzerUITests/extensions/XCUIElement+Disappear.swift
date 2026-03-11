//
//  XCUIElement+Disappear.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

extension XCUIElement {
	/// Waits for the element to appear within the timeout
	func awaitAppear(timeout: TimeInterval = 4) {
		XCTAssertTrue(waitForExistence(timeout: timeout), "Expected element to appear")
	}

	/// Waits for the element to disappear within the timeout
	func awaitDisappear(timeout: TimeInterval = 4) {
		// iOS 17+ has waitForNonExistence, but for compatibility use predicate
		let predicate = NSPredicate(format: "exists == false")
		let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
		let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
		XCTAssertEqual(result, .completed, "Expected element to disappear")
	}
}
