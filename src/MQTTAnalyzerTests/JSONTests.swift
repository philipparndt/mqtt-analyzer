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

extension Data {
	var prettyPrintedJSONString: NSString? {
		guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
			  let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
			  let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

		return prettyPrintedString
	}
}

import WebKit
class MyJSONParser {
	private static let webView = WKWebView()

	class func parse(jsonString: String, completionHandler: @escaping (Any?, Error?) -> Void) {
		self.webView.evaluateJavaScript(jsonString, completionHandler: completionHandler)
	}
}

import JavaScriptCore

class JSONTests: XCTestCase {
	func testWebKit() {
		let json = JSONUtils.format(json: "{\"hello\": 0.6}")
		print(json)
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
