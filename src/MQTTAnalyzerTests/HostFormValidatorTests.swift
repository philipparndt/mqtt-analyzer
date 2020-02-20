//
//  HostFormValidatorTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class HostFormValidatorTests: XCTestCase {
	func testClientIDEmptyRandom() {
		XCTAssertTrue(HostFormValidator.validateClientID(id: "", random: true) != nil)
	}

	func testClientIDEmptyNonRandom() {
		XCTAssertTrue(HostFormValidator.validateClientID(id: "", random: false) == nil)
	}
	
	func testTrimClientID() {
		XCTAssertEqual("myId", HostFormValidator.validateClientID(id: "  myId  ", random: false)!)
	}
}
