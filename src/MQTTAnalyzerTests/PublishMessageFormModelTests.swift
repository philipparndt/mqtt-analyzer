//
//  PublishMessageFormModelTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-07.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
@testable import MQTTAnalyzer

class PublishMessageFormModelTests: XCTestCase {
	func testChangeToSetSuffix() {
		let model = PublishMessageFormModel()
		model.topic = "hue/light/light1"
		XCTAssertEqual(model.topicSuffix, TopicSuffix.none)
		model.topicSuffix = .sset
		XCTAssertEqual(model.topicSuffix, TopicSuffix.sset)
		XCTAssertEqual(model.topic, "hue/light/light1/set")
	}

	func testChangeToGetSuffix() {
		let model = PublishMessageFormModel()
		model.topic = "hue/light/light1"
		XCTAssertEqual(model.topicSuffix, TopicSuffix.none)
		model.topicSuffix = .sget
		XCTAssertEqual(model.topicSuffix, TopicSuffix.sget)
		XCTAssertEqual(model.topic, "hue/light/light1/get")
	}

	func testChangeToStateSuffix() {
		let model = PublishMessageFormModel()
		model.topic = "hue/light/light1"
		XCTAssertEqual(model.topicSuffix, TopicSuffix.none)
		model.topicSuffix = .sstate
		XCTAssertEqual(model.topicSuffix, TopicSuffix.sstate)
		XCTAssertEqual(model.topic, "hue/light/light1/state")
	}

	func testChangeToNoneSuffix() {
		let model = PublishMessageFormModel()
		model.topic = "hue/light/light1/set"
		XCTAssertEqual(model.topicSuffix, TopicSuffix.sset)
		model.topicSuffix = .none
		XCTAssertEqual(model.topicSuffix, TopicSuffix.none)
		XCTAssertEqual(model.topic, "hue/light/light1")
	}
}
