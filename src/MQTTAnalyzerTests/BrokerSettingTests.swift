//
//  HostTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 04.10.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

final class BrokerSettingTests: XCTestCase {

	func regressionIssue161() throws {
		let setting = BrokerSetting()
		setting.port = 40_000
		XCTAssertEqual(setting.port, 40_000)
	}

}
