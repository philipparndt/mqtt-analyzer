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
	func testHexString() {
		XCTAssertEqual("01 02", Data([1, 2]).hexStringEncoded())
	}
	
	func testHexBlockString() {
		let expected = """
00: 0102 0304 0506 0708
08: 090a 0b0c

"""
		XCTAssertEqual(expected, Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]).hexBlockEncoded(len: 8))
	}

	func testHexBlockStringLen16() {
		let expected = """
00: 0102 0304 0506 0708 090a 0b0c 0d0e 0f10
10: 11

"""
		XCTAssertEqual(expected, Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]).hexBlockEncoded(len: 16))
	}
	
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
