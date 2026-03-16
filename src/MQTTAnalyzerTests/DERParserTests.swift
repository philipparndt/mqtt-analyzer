//
//  DERParserTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class DERParserTests: XCTestCase {

	func testParseTag_success() {
		var parser = DERParser(bytes: [0x30, 0x05])
		XCTAssertTrue(parser.parseTag(0x30))
		XCTAssertEqual(parser.position, 1)
	}

	func testParseTag_mismatch() {
		var parser = DERParser(bytes: [0x30, 0x05])
		XCTAssertFalse(parser.parseTag(0x02))
		XCTAssertEqual(parser.position, 0)
	}

	func testParseTag_emptyBuffer() {
		var parser = DERParser(bytes: [])
		XCTAssertFalse(parser.parseTag(0x30))
	}

	func testParseLength_shortForm() {
		var parser = DERParser(bytes: [0x7f])
		let length = parser.parseLength()
		XCTAssertEqual(length, 127)
		XCTAssertEqual(parser.position, 1)
	}

	func testParseLength_shortFormZero() {
		var parser = DERParser(bytes: [0x00])
		let length = parser.parseLength()
		XCTAssertEqual(length, 0)
	}

	func testParseLength_longFormOneOctet() {
		// 0x81 means long form with 1 length byte, 0xff = 255
		var parser = DERParser(bytes: [0x81, 0xff])
		let length = parser.parseLength()
		XCTAssertEqual(length, 255)
		XCTAssertEqual(parser.position, 2)
	}

	func testParseLength_longFormTwoOctets() {
		// 0x82 means long form with 2 length bytes, 0x01 0x00 = 256
		var parser = DERParser(bytes: [0x82, 0x01, 0x00])
		let length = parser.parseLength()
		XCTAssertEqual(length, 256)
		XCTAssertEqual(parser.position, 3)
	}

	func testParseLength_longFormLargeValue() {
		// 0x82 0x04 0x00 = 1024
		var parser = DERParser(bytes: [0x82, 0x04, 0x00])
		let length = parser.parseLength()
		XCTAssertEqual(length, 1024)
	}

	func testParseLength_emptyBuffer() {
		var parser = DERParser(bytes: [])
		let length = parser.parseLength()
		XCTAssertEqual(length, 0)
	}

	func testPeek() {
		let parser = DERParser(bytes: [0x30, 0x05])
		XCTAssertEqual(parser.peek(), 0x30)
		XCTAssertEqual(parser.position, 0) // Position should not change
	}

	func testPeek_emptyBuffer() {
		let parser = DERParser(bytes: [])
		XCTAssertEqual(parser.peek(), 0)
	}

	func testParseSequence() {
		// Typical SEQUENCE tag followed by length
		var parser = DERParser(bytes: [0x30, 0x10, 0x02, 0x01, 0x05])
		XCTAssertTrue(parser.parseTag(0x30))
		let length = parser.parseLength()
		XCTAssertEqual(length, 16)
		// Now we should be at the INTEGER tag
		XCTAssertTrue(parser.parseTag(0x02))
	}
}
