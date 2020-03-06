//
//  DiagramPathTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2020-03-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
@testable import MQTTAnalyzer

class DiagramPathTests: XCTestCase {

	func testStandardUsecase() {
		let path = DiagramPath("foo.bar")
		XCTAssertEqual("bar", path.lastSegment)
		XCTAssertEqual("foo", path.parentPath)
	}
	
	func testEndWithDot() {
		let path = DiagramPath("foo.bar.")
		XCTAssertEqual("", path.lastSegment)
		XCTAssertEqual("foo.bar", path.parentPath)
	}

	func testStartEndWithDot() {
		let path = DiagramPath(".foo.bar.")
		XCTAssertEqual("", path.lastSegment)
		XCTAssertEqual(".foo.bar", path.parentPath)
	}

	func testOnlyDot() {
		let path = DiagramPath(".")
		XCTAssertEqual("", path.lastSegment)
		XCTAssertEqual(".", path.parentPath)
	}

	func testEmpty() {
		let path = DiagramPath("")
		XCTAssertEqual("", path.lastSegment)
		XCTAssertEqual("", path.parentPath)
	}

}
