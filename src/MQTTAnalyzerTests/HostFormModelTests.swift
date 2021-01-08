//
//  AWSIOTPresetTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2020-05-09.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
@testable import MQTTAnalyzer

class HostFormModelTests: XCTestCase {

	func testIssue76() {
		var model = HostFormModel()
		model.limitMessagesBatch = "1"
		model.limitTopic = "2"
		model.hostname = "example.org"
		let host = Host()
		XCTAssertEqual(1000, host.limitMessagesBatch)
		XCTAssertEqual(250, host.limitTopic)
		let target = copyHost(target: host, source: model)!
		XCTAssertEqual(1, target.limitMessagesBatch)
		XCTAssertEqual(2, target.limitTopic)
	}
		
}
