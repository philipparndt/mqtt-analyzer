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
}
