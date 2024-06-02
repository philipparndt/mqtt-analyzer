//
//  TreeUtilsTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class TreeUtilsTests: XCTestCase {

    func testEmpty() throws {
		XCTAssertEqual("", TreeUtils.commomPrefix(subscriptions: []))
    }
	
	func testSubscribeAll() throws {
		XCTAssertEqual("", TreeUtils.commomPrefix(subscriptions: ["#"]))
	}
	
	func testRemoveHash() {
		XCTAssertEqual("some/topic", TreeUtils.commomPrefix(subscriptions: ["some/topic/#"]))
	}

	func testMultipleSubscriptions() {
		XCTAssertEqual("", TreeUtils.commomPrefix(subscriptions: [
			"some/topic/#",
			"another/topic/#"
		]))
		XCTAssertEqual("some/topic", TreeUtils.commomPrefix(subscriptions: [
			"some/topic/a/#",
			"some/topic/b/#",
			"some/topic/c/#"
		]))
	}
	
	func testDifferentPaths() {
		XCTAssertEqual("", TreeUtils.commomPrefix(subscriptions: [
			"sonos/#",
			"hue/button/kueche-mitte/#",
			"hue/light/kueche/kueche-1/#"
		]))
	}

	func testPlusWildcard() {
		XCTAssertEqual("", TreeUtils.commomPrefix(subscriptions: [
			"+/light/#"
		]))
		XCTAssertEqual("some/topic", TreeUtils.commomPrefix(subscriptions: [
			"some/topic/a/#",
			"some/topic/+/#",
			"some/topic/c/#"
		]))
	}
	
}
