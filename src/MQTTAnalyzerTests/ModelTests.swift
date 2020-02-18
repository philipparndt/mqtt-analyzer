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
	
	func rootWithLocalhost() -> (RootModel, Host) {
		let model = RootModel()
		let hostsModel = model.hostsModel
		let host = Host()
		host.hostname = "localhost"
		
		hostsModel.hosts += [host]
		return (model, host)
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
	
	func testWithqHostname() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "pisvr"), "pisvr")
	}
	
	func testWithIP() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "10.0.0.1")!, "10.0.0.1")
		XCTAssertEqual(HostFormValidator.validateHostname(name: " 10.0.0.1 ")!, "10.0.0.1")
	}
	
	func testWithDomainName() {
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org"), "test.mosquitto.org")
		XCTAssertEqual(HostFormValidator.validateHostname(name: "test.mosquitto.org  "), "test.mosquitto.org")
	}
}
