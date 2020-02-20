//
//  ReadstateTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 20.02.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import XCTest
@testable import MQTTAnalyzer

class ReadstateTests: XCTestCase {
	func testInitialUnread() {
		let state = Readstate()
		XCTAssertFalse(state.read)
	}

	func testMarkRead() {
		let state = Readstate()
		state.markRead()
		XCTAssertTrue(state.read)
	}
	
	func testMarkUnread() {
		let state = Readstate()
		state.markRead()
		state.markUnread()
		XCTAssertFalse(state.read)
	}
}
