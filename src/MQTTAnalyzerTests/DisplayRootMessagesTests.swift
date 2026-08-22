//
//  DisplayRootMessagesTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-08-22.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

/// The root of the displayed tree is the common prefix of the subscriptions, so it
/// can carry messages of its own instead of only having children. Both the topic
/// tree and the counters have to account for that.
class DisplayRootMessagesTests: XCTestCase {

	private func displayRoot(subscriptions: [String]) -> TopicTree {
		let prefix = TreeUtils.commomPrefix(subscriptions: subscriptions)
		let root = TopicTree()
		return prefix.isEmpty ? root : (root.addTopic(topic: prefix) ?? root)
	}

	private func publish(_ text: String, to topic: String, on root: TopicTree) {
		_ = root.addMessage(
			metadata: MsgMetadata.stub(),
			payload: MsgPayload.from(text: text),
			to: topic
		)
	}

	func testExactSubscriptionPutsMessagesOnTheDisplayRoot() {
		let root = displayRoot(subscriptions: ["test"])
		XCTAssertEqual("test", root.nameQualified)

		publish("hello", to: "test", on: root)

		XCTAssertEqual(1, root.messages.count)
		XCTAssertTrue(root.children.isEmpty)
		XCTAssertTrue(root.childrenDisplay.isEmpty)
		XCTAssertEqual(1, root.topicCount)
	}

	func testWildcardSubscriptionAlsoMatchesItsOwnLevel() {
		// `test/#` matches `test` as well, so the display root carries messages
		// even though the subscription uses a wildcard.
		let root = displayRoot(subscriptions: ["test/#"])
		XCTAssertEqual("test", root.nameQualified)

		publish("root", to: "test", on: root)
		publish("child", to: "test/child", on: root)

		XCTAssertEqual(1, root.messages.count)
		XCTAssertEqual(["child"], Array(root.children.keys))
		XCTAssertEqual(2, root.topicCount)
	}

	func testWildcardSubscriptionKeepsMessagesInChildren() {
		let root = displayRoot(subscriptions: ["test/#"])

		publish("child", to: "test/child", on: root)

		XCTAssertTrue(root.messages.isEmpty)
		XCTAssertEqual(["child"], Array(root.children.keys))
	}

	func testSubscribeAllKeepsMessagesInChildren() {
		let root = displayRoot(subscriptions: ["#"])
		XCTAssertEqual("", root.nameQualified)

		publish("hello", to: "test", on: root)

		XCTAssertTrue(root.messages.isEmpty)
		XCTAssertEqual(["test"], Array(root.children.keys))
	}
}
