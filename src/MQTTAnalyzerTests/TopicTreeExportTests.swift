//
//  TopicTreeExportTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-06-28.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class TopicTreeExportTests: XCTestCase {

	private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

	private func buildTree() -> TopicTree {
		let root = TopicTree()
		_ = root.addMessage(
			metadata: MsgMetadata.stub(date: fixedDate),
			payload: MsgPayload.from(text: "{\"value\": 21}"),
			to: "home/livingroom/temp"
		)
		_ = root.addMessage(
			metadata: MsgMetadata.stub(date: fixedDate),
			payload: MsgPayload.from(text: "on"),
			to: "home/kitchen/light"
		)
		// A topic without any message - must be skipped.
		_ = root.addTopic(topic: "home/garage")
		return root
	}

	// MARK: - 4.1 Subtree collection

	func testCollectsDescendantsAndSkipsMessageLessTopics() throws {
		let home = buildTree().getTopic(topic: "home")!
		let export = TopicTreeExport(node: home, exportedAt: fixedDate)

		XCTAssertEqual("home", export.root)
		// Only the two topics with a message; intermediate + message-less topics skipped.
		XCTAssertEqual(["home/kitchen/light", "home/livingroom/temp"], export.messages.map { $0.topic })
	}

	func testEntriesAreSortedByQualifiedTopic() throws {
		let home = buildTree().getTopic(topic: "home")!
		let export = TopicTreeExport(node: home, exportedAt: fixedDate)
		XCTAssertEqual(export.messages.map { $0.topic }, export.messages.map { $0.topic }.sorted())
	}

	func testLeafTopicYieldsSingleEntry() throws {
		let leaf = buildTree().getTopic(topic: "home/kitchen/light")!
		let export = TopicTreeExport(node: leaf, exportedAt: fixedDate)
		XCTAssertEqual(1, export.messages.count)
		XCTAssertEqual("home/kitchen/light", export.messages.first?.topic)
		XCTAssertEqual("on", export.messages.first?.payload)
	}

	func testJSONPayloadIsPreservedVerbatim() throws {
		let leaf = buildTree().getTopic(topic: "home/livingroom/temp")!
		let export = TopicTreeExport(node: leaf, exportedAt: fixedDate)
		// The payload keeps its original JSON string - it is not restructured.
		XCTAssertEqual("{\"value\": 21}", export.messages.first?.payload)
	}

	// MARK: - 4.2 JSON serialization

	func testJSONIsValidAndStable() throws {
		let home = buildTree().getTopic(topic: "home")!
		let first = TopicTreeExporter.serialize(node: home, format: .json, exportedAt: fixedDate)
		let second = TopicTreeExporter.serialize(node: home, format: .json, exportedAt: fixedDate)

		XCTAssertEqual(first, second, "JSON output must be byte-stable for an unchanged snapshot")

		let data = first.data(using: .utf8)!
		let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		XCTAssertEqual("home", parsed?["root"] as? String)
		let messages = parsed?["messages"] as? [[String: Any]]
		XCTAssertEqual(2, messages?.count)
	}

	// MARK: - 4.3 YAML serialization

	func testYAMLIsValidAndMatchesJSONData() throws {
		let home = buildTree().getTopic(topic: "home")!
		let yaml = TopicTreeExporter.serialize(node: home, format: .yaml, exportedAt: fixedDate)

		XCTAssertTrue(yaml.contains("root: home"))
		XCTAssertTrue(yaml.contains("topic: home/livingroom/temp"))
		XCTAssertTrue(yaml.contains("topic: home/kitchen/light"))
		// A JSON payload stays JSON: emitted verbatim as a block-literal scalar,
		// with no escaping and never restructured into nested YAML.
		XCTAssertTrue(yaml.contains("payload: |-"), "payload must use a block-literal scalar")
		XCTAssertTrue(yaml.contains("{\"value\": 21}"), "JSON payload must appear verbatim")
		XCTAssertFalse(yaml.contains("\\\""), "block literal must not escape quotes")
		XCTAssertFalse(yaml.contains("value: 21"), "payload must not be restructured into YAML")
		XCTAssertTrue(yaml.contains("retain: true"))
		XCTAssertTrue(yaml.contains("qos: 0"))
	}

	// MARK: - Binary payloads

	func testBinaryPayloadIsBase64Encoded() throws {
		let root = TopicTree()
		let bytes: [UInt8] = [0xFF, 0xFE, 0x00, 0x10, 0x20, 0x7F]
		_ = root.addMessage(
			metadata: MsgMetadata.stub(date: fixedDate),
			payload: MsgPayload(data: bytes),
			to: "home/roborock/map"
		)
		let node = root.getTopic(topic: "home/roborock/map")!
		let base64 = Data(bytes).base64EncodedString()

		let export = TopicTreeExport(node: node, exportedAt: fixedDate)
		XCTAssertEqual("base64", export.messages.first?.payloadEncoding)
		XCTAssertEqual(base64, export.messages.first?.payload)

		let json = TopicTreeExporter.serialize(node: node, format: .json, exportedAt: fixedDate)
		XCTAssertTrue(json.contains("\"payloadEncoding\" : \"base64\""))
		XCTAssertTrue(json.contains(base64))
		XCTAssertFalse(json.contains("bytes]"), "binary must be exported, not a placeholder")

		let yaml = TopicTreeExporter.serialize(node: node, format: .yaml, exportedAt: fixedDate)
		XCTAssertTrue(yaml.contains("payloadEncoding: base64"))
		XCTAssertTrue(yaml.contains(base64))
	}

	func testTextPayloadHasNoEncodingMarker() throws {
		let leaf = buildTree().getTopic(topic: "home/kitchen/light")!
		let export = TopicTreeExport(node: leaf, exportedAt: fixedDate)
		XCTAssertNil(export.messages.first?.payloadEncoding)

		let json = TopicTreeExporter.serialize(node: leaf, format: .json, exportedAt: fixedDate)
		XCTAssertFalse(json.contains("payloadEncoding"), "text payloads must omit the encoding marker")
	}

	func testYAMLAndJSONShareTopicSet() throws {
		let home = buildTree().getTopic(topic: "home")!
		let json = TopicTreeExporter.serialize(node: home, format: .json, exportedAt: fixedDate)
		let yaml = TopicTreeExporter.serialize(node: home, format: .yaml, exportedAt: fixedDate)

		let data = json.data(using: .utf8)!
		let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		let messages = (parsed?["messages"] as? [[String: Any]]) ?? []
		for message in messages {
			let topic = message["topic"] as! String
			XCTAssertTrue(yaml.contains("topic: \(topic)"), "YAML missing topic \(topic)")
		}
	}
}
