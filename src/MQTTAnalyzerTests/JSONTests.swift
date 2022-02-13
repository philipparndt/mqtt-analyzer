//
//  JSONTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-05.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
import swift_petitparser

@testable import MQTTAnalyzer

class JSONTests: XCTestCase {
	func testWebKit() {
		let json = JSONUtils.format(json: "{\"hello\": 0.6}")
		XCTAssertEqual(json,
  """
  {
    "hello": 0.6
  }
  """)
	}

	func testJSONFormat() {
		let content = """
		  {
			  "currentEnergyConsumption": { "unit": "kWh", "value": 0.8 },
			  "currentWaterConsumption": { "unit": "l", "value": 10 },
			  "energyForecast": 0.6,
			  "waterForecast": 0.4
		  }
		"""

		let formatted = JSONUtils.format(json: content)
		
		let expected = """
		{
		  "currentEnergyConsumption": {
		    "unit": "kWh",
		    "value": 0.8
		  },
		  "currentWaterConsumption": {
		    "unit": "l",
		    "value": 10
		  },
		  "energyForecast": 0.6,
		  "waterForecast": 0.4
		}
		"""
		
		XCTAssertEqual(expected, formatted)
	}
}
