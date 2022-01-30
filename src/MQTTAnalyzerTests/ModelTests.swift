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

	func modelWithOneMessage(messageData: String) -> (RootModel, TopicTree) {
		return modelWithMessages(messageData: messageData)
	}

	func modelWithMessages(messageData: String...) -> (RootModel, TopicTree) {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)

		for data in messageData {
			_ = messageModel.addMessage(
				metadata: MsgMetadata.stub(),
				payload: MsgPayload(data: Array(data.utf8)),
				to: "topic"
			)
		}
		
		// addTopic will actually get the topic here, as it is already created
		return (model, messageModel.addTopic(topic: "topic")!)
	}

	func testBooleanTruePropInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
	{"toggle": true}
	""")

		let model = messages.timeSeries
		let diagrams = model.getDiagrams()
		XCTAssertEqual(1, diagrams.count)
		let only = diagrams[0]
		XCTAssertEqual("toggle", only.path)
		let series = model.get(only)
		XCTAssertEqual(1, series.count)
		let onlyValue = series[0]
		XCTAssertTrue(onlyValue.value as! Bool)
	}

	func testBooleanFalsePropInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
	{"toggle": false}
	""")

		let series = messages.timeSeries
		let onlyValue = series.get(series.getDiagrams()[0])[0]
		XCTAssertFalse(onlyValue.value as! Bool)
	}

	func testNumberPropertyInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{"temperature": 22.1}
		""")

		let series = messages.timeSeries
		let onlyValue = series.get(series.getDiagrams()[0])[0]
		XCTAssertEqual(22.1, onlyValue.value as! Double)
	}

	func testStringPropertyInJSON() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{"status": "offline"}
		""")

		let series = messages.timeSeries
		let onlyValue = series.get(series.getDiagrams()[0])[0]
		XCTAssertEqual("offline", onlyValue.value as! String)
	}
	
	func testJSONPath() {
		let (_, messages) = modelWithOneMessage(messageData: """
		{
			"some": {
				"toggle": true
			}
		}
		""")

		let diagrams = messages.timeSeries.getDiagrams()
		XCTAssertEqual(1, diagrams.count)
		let only = diagrams[0]
		XCTAssertEqual("some.toggle", only.path)
	}
}
