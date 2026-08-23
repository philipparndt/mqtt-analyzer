//
//  FlatMessageNodesTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-08-22.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

/// The flat topic list is read on every render of the topic tree, so it is cached
/// and may only be recomputed when the set of topics carrying messages changes.
class FlatMessageNodesTests: XCTestCase {

	private func publish(_ text: String, to topic: String, on root: TopicTree) {
		_ = root.addMessage(
			metadata: MsgMetadata.stub(),
			payload: MsgPayload.from(text: text),
			to: topic
		)
	}

	private func tree(topics: Int, depth: Int = 3) -> TopicTree {
		let root = TopicTree()
		for i in 0..<topics {
			let segments = (0..<depth).map { "level\($0)-\((i / (10 * ($0 + 1))) % 10)" }
			publish("payload \(i)", to: (segments + ["topic\(i)"]).joined(separator: "/"), on: root)
		}
		return root
	}

	func testFlatListContainsEveryTopicWithMessagesSortedByPath() {
		let root = TopicTree()
		publish("a", to: "b/two", on: root)
		publish("b", to: "a/one", on: root)
		publish("c", to: "b/one", on: root)

		XCTAssertEqual(
			["a/one", "b/one", "b/two"],
			root.recusiveAllMessages.map { $0.nameQualified }
		)
	}

	func testFlatListIsCachedUntilTheTopicSetChanges() {
		let root = TopicTree()
		publish("a", to: "some/topic", on: root)
		_ = root.recusiveAllMessages
		XCTAssertNotNil(root.flatMessageNodes)

		// Another message on a known topic does not change the list
		publish("b", to: "some/topic", on: root)
		XCTAssertNotNil(root.flatMessageNodes)

		// A new topic does
		publish("c", to: "some/other", on: root)
		XCTAssertNil(root.flatMessageNodes)
		XCTAssertEqual(
			["some/other", "some/topic"],
			root.recusiveAllMessages.map { $0.nameQualified }
		)
	}

	func testFlatListDropsRemovedTopics() {
		let root = TopicTree()
		publish("a", to: "some/topic", on: root)
		publish("b", to: "some/other", on: root)
		_ = root.recusiveAllMessages

		root.getTopic(topic: "some/other")?.remove()

		XCTAssertEqual(["some/topic"], root.recusiveAllMessages.map { $0.nameQualified })
	}

	func testFlatListDropsTopicsWithoutMessages() {
		let root = TopicTree()
		publish("a", to: "some/topic", on: root)
		publish("b", to: "some/other", on: root)
		_ = root.recusiveAllMessages

		let topic = root.getTopic(topic: "some/other")!
		topic.delete(message: topic.messages[0])

		XCTAssertEqual(["some/topic"], root.recusiveAllMessages.map { $0.nameQualified })
	}

	func testClearEmptiesTheFlatList() {
		let root = TopicTree()
		publish("a", to: "some/topic", on: root)
		_ = root.recusiveAllMessages

		root.clear()

		XCTAssertTrue(root.recusiveAllMessages.isEmpty)
	}

	func testQualifiedNameStaysCorrectWhenCached() {
		let root = TopicTree()
		publish("a", to: "a/b/c", on: root)

		let node = root.getTopic(topic: "a/b/c")!
		XCTAssertEqual("a/b/c", node.nameQualified)
		XCTAssertEqual("a/b/c", node.nameQualified)
		XCTAssertEqual("a/b", node.parent?.nameQualified)
		XCTAssertEqual("", root.nameQualified)
	}

	func testFlatListPerformance() {
		let root = tree(topics: 2000)

		// Reading the list is what happens on every render of the topic tree
		measure {
			for _ in 0..<50 {
				XCTAssertEqual(2000, root.recusiveAllMessages.count)
			}
		}
	}
}
