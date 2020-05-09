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
	func testWithHostname() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "pisvr"), "pisvr")
	}
	
	func testUnicodeHostnameDoesNotWork() {
		XCTAssertNil(HostFormValidator.validateHostname(name: "pisvr💖"))
	}

	func testNoProtocolPrefix() {
		XCTAssertNil(HostFormValidator.validateHostname(name: "http://pisvr"))
		XCTAssertNil(HostFormValidator.validateHostname(name: "ssh://pisvr"))
		XCTAssertNil(HostFormValidator.validateHostname(name: "mqtt://pisvr"))
	}
	
	func testWithIP() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "10.0.0.1")!, "10.0.0.1")
		XCTAssertEqual(HostFormValidator.validateHostname(name: " 10.0.0.1 ")!, "10.0.0.1")
	}
	
	func testWithDomainName() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org"), "test.mosquitto.org")
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org  "), "test.mosquitto.org")
		XCTAssertEqual(HostFormValidator.validateHostname(name: "ec2-12-345-67-890.us-east-2.compute.fooaws.com"), "ec2-12-345-67-890.us-east-2.compute.fooaws.com")
	}

	func testClientIDEmptyRandom() {
		XCTAssertNotNil(HostFormValidator.validateClientID(id: "", random: true))
	}

	func testClientIDEmptyNonRandom() {
		XCTAssertNil(HostFormValidator.validateClientID(id: "", random: false))
	}
	
	func testTrimClientID() {
		XCTAssertEqual("myId", HostFormValidator.validateClientID(id: "  myId  ", random: false)!)
	}
	
	func testInvalidClientID() {
		XCTAssertNil(HostFormValidator.validateClientID(id: "abc/", random: false))
	}
	
	func testValidatePort() {
		XCTAssertEqual(1883, HostFormValidator.validatePort(port: "1883"))
		XCTAssertEqual(1, HostFormValidator.validatePort(port: "1"))
		XCTAssertEqual(65535, HostFormValidator.validatePort(port: "65535"))
	}
	
	func testTrimPort() {
		XCTAssertEqual(1883, HostFormValidator.validatePort(port: "  1883  "))
	}
	
	func testPortOutOfRange() {
		XCTAssertNil(HostFormValidator.validatePort(port: "65536"))
		XCTAssertNil(HostFormValidator.validatePort(port: "-1"))
	}
	
	func testNoPortNumer() {
		XCTAssertNil(HostFormValidator.validatePort(port: "no-port-number"))
	}
	
	func testValidateMaxMessagesBatch() {
		XCTAssertEqual(1500, HostFormValidator.validateMaxMessagesBatch(value: "1500"))
		XCTAssertEqual(1567, HostFormValidator.validateMaxMessagesBatch(value: " 1567 "))
		XCTAssertNil(HostFormValidator.validateMaxMessagesBatch(value: "no number"))
		XCTAssertNil(HostFormValidator.validateMaxMessagesBatch(value: "2501"))
	}
	
	func testValidateMaxTopics() {
		XCTAssertEqual(1500, HostFormValidator.validateMaxTopic(value: "1500"))
		XCTAssertEqual(1567, HostFormValidator.validateMaxTopic(value: " 1567 "))
		XCTAssertNil(HostFormValidator.validateMaxTopic(value: "no number"))
		XCTAssertNil(HostFormValidator.validateMaxTopic(value: "2501"))
	}
}
