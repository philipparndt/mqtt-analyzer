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
		XCTAssertEqual("some", topic.nextLevel(hierarchy: Topic(""))?.segments.joined(separator: "/"))
		XCTAssertEqual("some/sensor/topic/A", topic.nextLevel(hierarchy: Topic(""))?.fullTopic)

		XCTAssertEqual("sensor", topic.nextLevel(hierarchy: Topic("some"))?.name)
		XCTAssertEqual("some/sensor/topic", topic.nextLevel(hierarchy: Topic("some/sensor"))?.segments.joined(separator: "/"))
		XCTAssertEqual("topic", topic.nextLevel(hierarchy: Topic("some/sensor"))?.name)
		XCTAssertEqual("some/sensor/topic/A", topic.nextLevel(hierarchy: Topic("some/sensor"))?.fullTopic)
		
		XCTAssertNil(topic.nextLevel(hierarchy: Topic("some/sensor/topic/A")))
		XCTAssertNil(topic.nextLevel(hierarchy: Topic("B")))
	}
	
	func testNoMoreSubTopics() {
		let topic = Topic("some/sensor/topic/A")
		XCTAssertNil(topic.nextLevel(hierarchy: topic))
	}
	
	func testLastSubTopic() {
		let topic = Topic("hue/zgp_connectivity/buero")
		XCTAssertEqual("buero", topic.nextLevel(hierarchy: Topic("hue/zgp_connectivity"))?.name)
	}
	
	func testSamePrefix() {
		let topic = Topic("hue/button/buero-hue-smart-button")
		XCTAssertNil(topic.nextLevel(hierarchy: Topic("hue/button/buero")))
	}
}
