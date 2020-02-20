//
//  StringUtilsTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class StringUtilsTests: XCTestCase {
	func testTruncate() {
		XCTAssertEqual("ab…", "abcde".truncate(length: 2))
		XCTAssertEqual("ab...", "abcde".truncate(length: 2, trailing: "..."))
	}
	
	func testPathUp() {
		XCTAssertEqual("/a/b/c", "/a/b/c/d".pathUp())
		XCTAssertEqual("/a/b", "/a/b/c/d".pathUp().pathUp())
		XCTAssertEqual("/a", "/a/b/c/d".pathUp().pathUp().pathUp())
		XCTAssertEqual("/a", "/a/b/c/d".pathUp().pathUp().pathUp().pathUp())
		XCTAssertEqual("/a", "/a/b/c/d".pathUp().pathUp().pathUp().pathUp().pathUp())
	}
	
	func testPathUpNoPath() {
		XCTAssertEqual("", "foo".pathUp())
	}
	
	func testBlank() {
		XCTAssertTrue("".isBlank)
		XCTAssertTrue(" ".isBlank)
		XCTAssertTrue(" \t\r\n\n".isBlank)
	}
	
	func testNonBlank() {
		XCTAssertFalse(" huhu".isBlank)
	}
}
