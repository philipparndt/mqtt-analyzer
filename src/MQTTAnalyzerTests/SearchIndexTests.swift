//
//  SearchIndexTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-02-25.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import DSFFullTextSearchIndex
@testable import MQTTAnalyzer

class SearchIndexTests: XCTestCase {
	func message(to: TopicTree, topic: String, payload: String) {
		XCTAssertNotNil(to.addMessage(
			metadata: MsgMetadata.stub(),
			payload: MsgPayload.from(text: payload),
			to: topic
		))
	}
	
	func testSearch() {
		let root = TopicTree()
		message(to: root, topic: "home/example/a", payload: "some message")
		message(to: root, topic: "home/example/b", payload: "another message")

		XCTAssertEqual(root.search(text: "some"), ["home/example/a"])
		XCTAssertEqual(root.search(text: "another"), ["home/example/b"])
		XCTAssertEqual(root.search(text: "message"), [
			"home/example/a",
			"home/example/b"
		])
	}
	
	func testClear() {
		let root = TopicTree()
		message(to: root, topic: "home/example/a", payload: "some message")
		message(to: root, topic: "home/example/b", payload: "another message")

		root.clear()
		XCTAssertEqual(0, root.children.count)
		
		XCTAssertEqual(root.search(text: "some"), [])
		XCTAssertEqual(root.search(text: "another"), [])
		XCTAssertEqual(root.search(text: "message"), [])
		
		XCTAssertEqual(0, root.children.count)
	}
	
	func testCaseInsensitive() {
		let root = TopicTree()
		message(to: root, topic: "home/example/a", payload: "Some message")
		
		XCTAssertEqual(root.search(text: "sOME"), ["home/example/a"])
	}
	
	func testMatchStart() {
		let root = TopicTree()
		message(to: root, topic: "home/example/a", payload: "Some message")
		
		XCTAssertEqual(root.search(text: "So*"), ["home/example/a"])
	}
	
	func testReplace() {
		let root = TopicTree()
		message(to: root, topic: "home/example/a", payload: "Some message")
		message(to: root, topic: "home/example/a", payload: "Another message")

		XCTAssertEqual(root.search(text: "So*"), [])
	}
	
	func testFindTopic() {
		let root = TopicTree()
		message(to: root, topic: "home/some", payload: "a")
		message(to: root, topic: "home/another", payload: "a")

		XCTAssertEqual(root.search(text: "some"), ["home/some"])
		XCTAssertEqual(root.search(text: "another"), ["home/another"])
	}

	func testSubfilter() {
		let root = TopicTree()
		message(to: root, topic: "home/lights/a", payload: "ON")
		message(to: root, topic: "home/lights/b", payload: "ON")
		message(to: root, topic: "home/lights/c", payload: "OFF")

		message(to: root, topic: "home/fans/a", payload: "ON")

		let lights = root.addTopic(topic: "home/lights")!
		XCTAssertEqual(lights.search(text: "ON").sorted { $0 < $1 },
					   ["home/lights/a", "home/lights/b"]
		)

		let fans = root.addTopic(topic: "home/fans")!
		XCTAssertEqual(fans.search(text: "ON").sorted { $0 < $1 }, ["home/fans/a"])
	}
}
