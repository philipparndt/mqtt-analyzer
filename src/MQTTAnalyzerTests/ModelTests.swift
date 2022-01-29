//
//  ModelTest.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 18.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class ModelTests: XCTestCase {

	func rootWithLocalhost() -> (RootModel, Host) {
		let model = RootModel()
		let hostsModel = model.hostsModel
		let host = Host()
		host.hostname = "localhost"
		
		hostsModel.hosts += [host]
		return (model, host)
	}

	func modelWithOneMessage(messageData: String) -> (RootModel, MessagesByTopic) {
		return modelWithMessages(messageData: messageData)
	}

	func modelWithMessages(messageData: String...) -> (RootModel, MessagesByTopic) {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		for data in messageData {
			messageModel.append(message: Message(
				topic: "topic",
				payload: MsgPayload(data: Array(data.utf8)),
				metadata: MsgMetadata.stub()
			))
		}
		return (model, messageModel.messagesByTopic["topic"]!)
	}
	
	func topicOfMessages(messageData: String...) -> MessagesByTopic {
		let (root, _) = modelWithMessages(messageData: "a", "b")
		let host = root.messageModelByHost.keys.first!
		let messageModel = root.getMessageModel(host)
		let topicEntry = messageModel.messagesByTopic.first!
		return topicEntry.value
	}

	func testAppendMessage() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		XCTAssertEqual(0, messageModel.countMessages())
		messageModel.append(message: Message(
			topic: "topic",
			payload: MsgPayload(data: Array("text message".utf8)),
			metadata: MsgMetadata.stub()
		))

		XCTAssertEqual(1, messageModel.countMessages())
		let message = messageModel.messagesByTopic["topic"]!.messages[0]
		XCTAssertFalse(message.payload.isJSON)
	}
	
	func testLimitTopics() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		messageModel.limitTopics = 10
		
		for i in 0...15 {
			messageModel.append(message: Message(
				topic: "topic/\(i)",
				payload: MsgPayload(data: Array("text message".utf8)),
				metadata: MsgMetadata.stub()
			))
		}
		
		XCTAssertEqual(10, messageModel.countMessages())
	}
	
	func testMessagesNotAffectedByTopicLimit() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		messageModel.limitTopics = 10
		
		for _ in 0..<15 {
			messageModel.append(message: Message(
				topic: "topic",
				payload: MsgPayload(data: Array("text message".utf8)),
				metadata: MsgMetadata.stub()
			))
		}
		
		XCTAssertEqual(15, messageModel.countMessages())
	}
		
	func testJSONMessage() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		XCTAssertEqual(0, messageModel.countMessages())
		let msg = """
{"toggle": true}
"""
		
		messageModel.append(message: Message(
			topic: "topic",
			payload: MsgPayload(data: Array(msg.utf8)),
			metadata: MsgMetadata.stub()
		))

		XCTAssertEqual(1, messageModel.countMessages())
		let message = messageModel.messagesByTopic["topic"]!.messages[0]
		XCTAssertTrue(message.payload.isJSON)
	}

	func testBooleanTruePropInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
	{"toggle": true}
	""")
		
		let diagrams = messages.getDiagrams()
		XCTAssertEqual(1, diagrams.count)
		let only = diagrams[0]
		XCTAssertEqual("toggle", only.path)
		let series = messages.getTimeSeries(only)
		XCTAssertEqual(1, series.count)
		let onlyValue = series[0]
		XCTAssertTrue(onlyValue.value as! Bool)
	}

	func testBooleanFalsePropInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
	{"toggle": false}
	""")
		
		let onlyValue = messages.getTimeSeries(messages.getDiagrams()[0])[0]
		XCTAssertFalse(onlyValue.value as! Bool)
	}
	
	func testNumberPropertyInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{"temperature": 22.1}
		""")
			
		let onlyValue = messages.getTimeSeries(messages.getDiagrams()[0])[0]
		XCTAssertEqual(22.1, onlyValue.value as! Double)
	}
	
	func testStringPropertyInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{"status": "offline"}
		""")
			
		let onlyValue = messages.getTimeSeries(messages.getDiagrams()[0])[0]
		XCTAssertEqual("offline", onlyValue.value as! String)
	}

	func testRecentMessage() {
		let (_, messages) = modelWithMessages(messageData: "1st", "2nd")
		
		XCTAssertEqual("2nd", messages.getRecent())
	}
	
	func testJSONPath() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{
			"some": {
				"toggle": true
			}
		}
		""")
			
		let diagrams = messages.getDiagrams()
		XCTAssertEqual(1, diagrams.count)
		let only = diagrams[0]
		XCTAssertEqual("some.toggle", only.path)
	}
	
	func testClearTopics() {
		let (root, _) = modelWithMessages(messageData: "a", "b")
		let host = root.messageModelByHost.keys.first!
		let messageModel = root.getMessageModel(host)
		XCTAssertEqual(2, messageModel.countMessages())
		messageModel.clear()
		XCTAssertEqual(0, messageModel.countMessages())
	}
	
	func testClearMessagesFromTopic() {
		let topic = topicOfMessages(messageData: "a", "b")
		XCTAssertFalse(topic.messages.isEmpty)
		topic.clear()
		XCTAssertTrue(topic.messages.isEmpty)
	}
	
	func testMarkRead() {
		let (root, _) = modelWithMessages(messageData: "a", "b")
		let host = root.messageModelByHost.keys.first!
		let messageModel = root.getMessageModel(host)
		let topicEntry = messageModel.messagesByTopic.first!
		let topic = topicEntry.value
		XCTAssertFalse(topic.read.read)
		messageModel.readall()
		XCTAssertTrue(topic.read.read)
	}
		
}
