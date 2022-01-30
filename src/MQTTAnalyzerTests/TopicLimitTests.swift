//
//  TopicLimitTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class TopicLimitTests: XCTestCase {
    func testDoNotAddWhenLimitActive() throws {
		let root = TopicTree()
		for i in 0...10 {
			XCTAssertNotNil(root.addTopic(topic: "\(i)"))
		}
		
		root.topicLimitExceeded = true
		for i in 0...10 {
			// This will just get the topics created previously
			XCTAssertNotNil(root.addTopic(topic: "\(i)"))
		}

		// No more topics
		for i in 11...20 {
			XCTAssertNil(root.addTopic(topic: "\(i)"))
		}
    }
	
	func testCannotAddMessageToNewTopic() throws {
		let root = TopicTree()
		for i in 0...10 {
			XCTAssertNotNil(root.addMessage(
				metadata: MsgMetadata.stub(),
				payload: MsgPayload.from(text: "\(i)"),
				to: "\(i)"))
		}
		
		root.topicLimitExceeded = true
		for i in 0...10 {
			// This will just add messages to existing topics
			XCTAssertNotNil(root.addMessage(
				metadata: MsgMetadata.stub(),
				payload: MsgPayload.from(text: "\(i) changed"),
				to: "\(i)"))
		}

		// No more topics
		for i in 11...20 {
			XCTAssertNil(root.addMessage(
				metadata: MsgMetadata.stub(),
				payload: MsgPayload.from(text: "\(i) changed"),
				to: "\(i)"))
		}
	}
}
