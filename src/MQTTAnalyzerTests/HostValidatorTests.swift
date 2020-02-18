//
//  HostValidatorTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class HostValidatorTests: XCTestCase {
	func testWithqHostname() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "pisvr"), "pisvr")
	}
	
	func testWithIP() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "10.0.0.1")!, "10.0.0.1")
		XCTAssertEqual(HostFormValidator.validateHostname(name: " 10.0.0.1 ")!, "10.0.0.1")
	}
	
	func testWithDomainName() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org"), "test.mosquitto.org")
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org  "), "test.mosquitto.org")
	}
}
