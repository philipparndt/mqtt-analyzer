//
//  TopicLimitTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class TimeSeriesTests: XCTestCase {
	func windMsg(_ value: Double) -> String {
		return """
		{ "wind": \(value) }
		"""
	}
	
	func date(_ minute: Int) -> Date {
		let isoDate = "2022-06-17T10:\(String(format: "%02d", minute)):00+0000"

		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		return dateFormatter.date(from: isoDate)!
	}
	
	func add(minute: Int, wind: Double, to: TopicTree) {
		_ = to.addMessage(
			metadata: MsgMetadata.stub(date: date(minute)),
				payload: MsgPayload(data: Array(windMsg(wind).utf8)),
				to: "wind"
			)
	}
	
	func testGroupFirst() throws {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		add(minute: 0, wind: 4, to: messageModel)
		
		let series = messageModel.getTopic(topic: "wind")?.timeSeries
		let values = series!.getGrouped(DiagramPath("wind"))
		
		XCTAssertEqual(1, values.count)
		XCTAssertEqual(4, values[0].min)
		XCTAssertEqual(4, values[0].max)
		XCTAssertEqual(4, values[0].average)
	}
	
	func testGrouping() throws {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		add(minute: 0, wind: 4, to: messageModel)
		add(minute: 0, wind: 8, to: messageModel)
		
		let series = messageModel.getTopic(topic: "wind")?.timeSeries
		let values = series!.getGrouped(DiagramPath("wind"))
		
		XCTAssertEqual(1, values.count)
		XCTAssertEqual(4, values[0].min)
		XCTAssertEqual(8, values[0].max)
		XCTAssertEqual(6, values[0].average)
	}
	
	func testGroupingMinutes() throws {
		let (model, host) = rootWithLocalhost()
		let messageModel = model.getMessageModel(host)
		add(minute: 0, wind: 4, to: messageModel)
		add(minute: 1, wind: 8, to: messageModel)
		
		let series = messageModel.getTopic(topic: "wind")?.timeSeries
		let values = series!.getGrouped(DiagramPath("wind"))
		
		XCTAssertEqual(2, values.count)
		XCTAssertEqual(4, values[0].min)
		XCTAssertEqual(4, values[0].max)
		XCTAssertEqual(4, values[0].average)
		
		XCTAssertEqual(8, values[1].min)
		XCTAssertEqual(8, values[1].max)
		XCTAssertEqual(8, values[1].average)
	}
}
