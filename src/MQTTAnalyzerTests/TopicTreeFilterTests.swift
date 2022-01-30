//
//  TopicTreeFilterTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

extension TopicTree {
	func matchesJoined() -> String {
		return childrenDisplay
			.map { $0.nameQualified }
			.sorted().joined(separator: ", ")
	}
}

class TopicTreeFilterTests: XCTestCase {
	
	func testBlankFilter() throws {
		let root = TopicTree()
		_ = root.addTopic(topic: "some")
		_ = root.addTopic(topic: "another")
		
		XCTAssertEqual("another, some", root.matchesJoined())
	}
	
	func testSomeFilter() throws {
		let root = TopicTree()
		root.filterText = "some"
		_ = root.addTopic(topic: "some")
		_ = root.addTopic(topic: "another")
		
		XCTAssertEqual("some", root.matchesJoined())
	}
	
	func testAnotherFilter() throws {
		let root = TopicTree()
		root.filterText = "another"
		_ = root.addTopic(topic: "some")
		_ = root.addTopic(topic: "another")
		
		XCTAssertEqual("another", root.matchesJoined())
	}
	
	func testPartialFilter() throws {
		let root = TopicTree()
		root.filterText = "some"
		_ = root.addTopic(topic: "some")
		_ = root.addTopic(topic: "someother")
		_ = root.addTopic(topic: "another")

		XCTAssertEqual("some, someother", root.matchesJoined())
	}
	
	func testCaseInsensitiveFilter() throws {
		let root = TopicTree()
		root.filterText = "Some"
		_ = root.addTopic(topic: "sOme")
		_ = root.addTopic(topic: "soMEother")
		_ = root.addTopic(topic: "another")

		XCTAssertEqual("sOme, soMEother", root.matchesJoined())
	}
	
	func testUpdateFilter() throws {
		let root = TopicTree()
		_ = root.addTopic(topic: "sOme")
		_ = root.addTopic(topic: "soMEother")
		_ = root.addTopic(topic: "another")
		root.filterText = "Some"

		XCTAssertEqual("sOme, soMEother", root.matchesJoined())
	}
	
	func testMatchChildren() throws {
		let root = TopicTree()
		_ = root.addTopic(topic: "home/hue/light/office")
		root.filterText = "office"

		XCTAssertEqual("home", root.matchesJoined())
	}
	
	func testElementsAddedWhenNotMatching() throws {
		let root = TopicTree()
		root.filterText = "office"
		_ = root.addTopic(topic: "home/hue/light/office")
		_ = root.addTopic(topic: "other/sensor")
		XCTAssertEqual("home", root.matchesJoined())
		
		root.filterText = ""
		XCTAssertEqual("home, other", root.matchesJoined())
	}
	
	func testNoMatchChildren() throws {
		let root = TopicTree()
		_ = root.addTopic(topic: "home/hue/light/office")
		root.filterText = "other"

		XCTAssertEqual("", root.matchesJoined())
	}
}
