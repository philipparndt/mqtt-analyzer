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
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		XCTAssertEqual(0, messageModel.countMessages())
		messageModel.append(message: Message(data: messageData,
											 date: Date(),
											 qos: 0,
											 retain: false,
											 topic: "topic"))

		XCTAssertEqual(1, messageModel.countMessages())
		return (model, messageModel.messagesByTopic["topic"]!)
	}
	
	func testAppendMessage() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		XCTAssertEqual(0, messageModel.countMessages())
		messageModel.append(message: Message(data: "text message",
											 date: Date(),
											 qos: 0,
											 retain: false,
											 topic: "topic"))

		XCTAssertEqual(1, messageModel.countMessages())
		let message = messageModel.messagesByTopic["topic"]!.messages[0]
		XCTAssertFalse(message.isJson())
	}
	
	func testLimitTopics() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		messageModel.limitTopics = 10
		
		for i in 0...15 {
			messageModel.append(message: Message(data: "text message",
												 date: Date(),
												 qos: 0,
												 retain: false,
												 topic: "topic/\(i)"))
		}
		
		XCTAssertEqual(10, messageModel.countMessages())
	}
	
	func testMessagesNotAffectedByTopicLimit() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		messageModel.limitTopics = 10
		
		for _ in 0..<15 {
			messageModel.append(message: Message(data: "text message",
												 date: Date(),
												 qos: 0,
												 retain: false,
												 topic: "topic"))
		}
		
		XCTAssertEqual(15, messageModel.countMessages())
	}
		
	func testJSONMessage() {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		XCTAssertEqual(0, messageModel.countMessages())
		messageModel.append(message: Message(data: """
												{"toggle": true}
												""",
											 date: Date(),
											 qos: 0,
											 retain: false,
											 topic: "topic"))

		XCTAssertEqual(1, messageModel.countMessages())
		let message = messageModel.messagesByTopic["topic"]!.messages[0]
		XCTAssertTrue(message.isJson())
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

}
