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
    func testValidateHostname() {
        XCTAssertEqual(HostValidator.validateHostname(name: "10.0.0.1")!, "10.0.0.1")
        XCTAssertEqual(HostValidator.validateHostname(name: " 10.0.0.1 ")!, "10.0.0.1")
//        XCTAssertEqual(HostValidator.validateHostname(name: "pisvr"), "pisvr")
//        XCTAssertEqual(HostValidator.validateHostname(name: "test.mosquitto.org"), "test.mosquitto.org")
//        XCTAssertEqual(HostValidator.validateHostname(name: "test.mosquitto.org  "), "test.mosquitto.org")
    }
}
