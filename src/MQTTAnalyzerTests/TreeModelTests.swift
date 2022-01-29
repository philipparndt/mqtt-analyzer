//
//  TreeModelTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class TreeModelTests: XCTestCase {

    func testTreeRoot() throws {
		let root = TopicTree()
		XCTAssertEqual("root", root.name)
		XCTAssertEqual("root", root.nameQualified)
		XCTAssertEqual(0, root.messages.count)
    }
	
	func testSimpleTree() throws {
		let root = TopicTree()
		let home = TopicTree(name: "home", parent: root)
		let hue = TopicTree(name: "hue", parent: home)

		XCTAssertEqual("home/hue", hue.nameQualified)
		XCTAssertEqual("home", hue.parent?.name)
		
		XCTAssertEqual("home/hue", home.children["hue"]?.nameQualified)
	}
	
	func testAddTopic() throws {
		let root = TopicTree()
		let node = root.addTopic(topic: "home/hue/button/office")
		XCTAssertEqual("home/hue/button/office", node.nameQualified)
		XCTAssertIdentical(node, root.addTopic(topic: "home/hue/button/office"))
	}
	
	func testAddAnotherTopic() throws {
		let root = TopicTree()
		let button = root.addTopic(topic: "home/hue/button/office")
		let light = root.addTopic(topic: "home/hue/light/office")
		let hue = root.addTopic(topic: "home/hue")
		XCTAssertEqual("home/hue", hue.nameQualified)
		XCTAssertEqual("home/hue/button/office", button.nameQualified)
		XCTAssertEqual("home/hue/light/office", light.nameQualified)
		XCTAssertEqual(2, hue.children.count)
	}

	func testAddMessage() throws {
		let root = TopicTree()
		let metadata = MsgMetadata(qos: 0, retain: true)
		let payload = MsgPayload(data: Array("Hello".utf8))
		let message = root.addMessage(metadata: metadata, payload: payload, to: "home/hue/button/office")
		XCTAssertEqual("Hello", message.payload.dataString)
		
		let button = root.addTopic(topic: "home/hue/button/office")
		XCTAssertEqual(1, button.messages.count)
	}
	
	func testBinaryPayload() throws {
		let payload = MsgPayload(data: [0x78, 0x9C, 0x8D])
		XCTAssertTrue(payload.isBinary)
		XCTAssertFalse(payload.isJSON)
		XCTAssertEqual("[3 bytes]", payload.dataString)
	}
	
	func testJSONPayload() throws {
		XCTAssertTrue(MsgPayload(data: Array("{\"on\": true}".utf8)).isJSON)
	}
	
	func testNonJSONPayload() throws {
		let payload = MsgPayload(data: Array("Hello".utf8))
		XCTAssertEqual("Hello", payload.dataString)
		XCTAssertFalse(payload.isJSON)
	}

	func testJSONPayloadPretty() throws {
		let payload = MsgPayload(data: Array("{\"on\": true}".utf8))
		XCTAssertEqual("""
{
  "on": true
}
""", payload.prettyJSON)
	}
}
