//
//  StringUtilsTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class LoggerTests: XCTestCase {
	func doLog(logger: Logger) {
		logger.error("error")
		logger.warning("warning")
		logger.info("info")
		logger.debug("debug")
		logger.trace("trace")
	}
	
	func testInitialEmpty() {
		let logger = Logger(level: .none)
		XCTAssertEqual(0, logger.messages.count)
	}
	
	func testNone() {
		let logger = Logger(level: .none)
		doLog(logger: logger)
		XCTAssertEqual(0, logger.messages.count)
	}
	
	func testError() {
		let logger = Logger(level: .error)
		doLog(logger: logger)
		XCTAssertEqual(1, logger.messages.count)
	}
	
	func testWarn() {
		let logger = Logger(level: .warning)
		doLog(logger: logger)
		XCTAssertEqual(2, logger.messages.count)
	}
	
	func testInfo() {
		let logger = Logger(level: .info)
		doLog(logger: logger)
		XCTAssertEqual(3, logger.messages.count)
	}
	
	func testDebug() {
		let logger = Logger(level: .debug)
		doLog(logger: logger)
		XCTAssertEqual(4, logger.messages.count)
	}
	
	func testTrace() {
		let logger = Logger(level: .trace)
		doLog(logger: logger)
		XCTAssertEqual(5, logger.messages.count)
	}

}
