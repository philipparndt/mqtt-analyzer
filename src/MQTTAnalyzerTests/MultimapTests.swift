//
//  MultimapTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class MultimapTests: XCTestCase {
	func testPutFirst() {
		let map = Multimap<String, String>()
		map.put(key: "key", value: "1st")
		XCTAssertEqual(1, map.dict.keys.count)
		map.put(key: "key", value: "2nd")
		XCTAssertEqual(1, map.dict.keys.count)
		XCTAssertEqual(2, map.dict["key"]!.count)
	}
}
