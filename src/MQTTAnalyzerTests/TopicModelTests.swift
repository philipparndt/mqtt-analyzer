//
//  TopicModelTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class TopicModelTests: XCTestCase {
	func testOnlyOneSegement() {
		let topic = Topic("root")
		XCTAssertEqual("root", topic.lastSegment)
	}

	func testMultipleSegments() {
		let topic = Topic("A/B/C")
		XCTAssertEqual("C", topic.lastSegment)
	}
	
	func testNextLevel() {
		let topic = Topic("some/sensor/topic/A")
		XCTAssertEqual("some", topic.nextLevel(hierarchy: Topic(""))?.name)
		XCTAssertEqual("some/sensor", topic.nextLevel(hierarchy: Topic("some"))?.name)
		XCTAssertEqual("some/sensor/topic", topic.nextLevel(hierarchy: Topic("some/sensor"))?.name)
		XCTAssertNil(topic.nextLevel(hierarchy: Topic("some/sensor/topic/A")))
		XCTAssertNil(topic.nextLevel(hierarchy: Topic("B")))
	}
	
	func testNoMoreSubTopics() {
		let topic = Topic("some/sensor/topic/A")
		XCTAssertNil(topic.nextLevel(hierarchy: topic))
	}
	
	func testLastSubTopic() {
		let topic = Topic("hue/zgp_connectivity/buero")
		XCTAssertEqual("hue/zgp_connectivity/buero", topic.nextLevel(hierarchy: Topic("hue/zgp_connectivity"))?.name)
	}
}
