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

class PropertyImageProviderTests: XCTestCase {
	func testAlreadyInDict() {
		XCTAssertEqual("wifi", PropertyImageProvider.byName(property: "connection"))
		XCTAssertEqual("wifi", PropertyImageProvider.byName(property: "Connection"))
		XCTAssertEqual("wifi", PropertyImageProvider.byName(property: "Wifi"))
	}
	
	func testSubstring() {
		XCTAssertEqual("wifi", PropertyImageProvider.byName(property: "wifiQuality"))
		XCTAssertEqual("wifi", PropertyImageProvider.byName(property: "wifi_quality"))
		XCTAssertEqual("battery.100", PropertyImageProvider.byName(property: "battery_level"))
		XCTAssertEqual("battery.100", PropertyImageProvider.byName(property: "battery_state"))
		XCTAssertEqual("chart.bar", PropertyImageProvider.byName(property: "update_available"))
	}
	
	func testOther() {
		XCTAssertEqual("chart.bar", PropertyImageProvider.byName(property: "other"))
	}
}
