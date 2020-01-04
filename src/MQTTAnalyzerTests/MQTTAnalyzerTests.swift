//
//  MQTTAnalyzerTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class MQTTAnalyzerTests: XCTestCase {

	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testMenValuesForOnHourAreCreated() {
		let model = MTimeSeriesModel()
		let values = model.getMeanValue(amount: 60, in: 1, to: Date(timeIntervalSince1970: 60 * 60))
		
		XCTAssertEqual(60, values.count)
	}
	
	func testFilterValuesInRangeEmpty() {
		let model = MTimeSeriesModel()
		let inRange = model.valuesInRange(values: model.values, from: Date(timeIntervalSince1970: 0), to: Date(timeIntervalSince1970: 60 * 60))
		
		XCTAssertTrue(inRange.isEmpty)
	}
	
	func testFilterValuesInRange() {
		let model = MTimeSeriesModel()
		model.values.append(MTimeSeriesValue(value: 1, timestamp: Date(timeIntervalSince1970: 0)))
		model.values.append(MTimeSeriesValue(value: 2, timestamp: Date(timeIntervalSince1970: 50)))
		model.values.append(MTimeSeriesValue(value: 3, timestamp: Date(timeIntervalSince1970: 60 * 60 * 2)))
		
		let inRange = model.valuesInRange(values: model.values, from: Date(timeIntervalSince1970: 0), to: Date(timeIntervalSince1970: 60 * 60))
		XCTAssertEqual(2, inRange.count)
	}
	
	func testEmptyMean() {
		let model = MTimeSeriesModel()
		let mean = model.buildMean(value: [MTimeSeriesValue]())
		XCTAssertFalse(mean.meanValue != nil)
	}

	func testMeanOfOneValue() {
		let model = MTimeSeriesModel()
		let mean = model.buildMean(value: [
			MTimeSeriesValue(value: 1, timestamp: Date())]
		)
		XCTAssertEqual(1, mean.meanValue!)
	}
	
	func testMeanOfSomeValues() {
		let model = MTimeSeriesModel()
		let mean = model.buildMean(value: [
			MTimeSeriesValue(value: 1, timestamp: Date()),
			MTimeSeriesValue(value: 2, timestamp: Date()),
			MTimeSeriesValue(value: 3, timestamp: Date())
			]
		)
		XCTAssertEqual(2, mean.meanValue!)
	}
	
//	func testPerformanceExample() {
//		// This is an example of a performance test case.
//		self.measure {
//			// Put the code you want to measure the time of here.
//		}
//	}

}
