//
//  JSONUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-06.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import JavaScriptCore

let jsSource = "var formatJSON = function(jsonStr) { return JSON.stringify(JSON.parse(jsonStr.trim()), null, 2)}"
let context = JSContext()

public class JSONUtils {
	class func format(json: String) -> String {
		context?.evaluateScript(jsSource)
		
		let function = context?.objectForKeyedSubscript("formatJSON")
		if let result = function?.call(withArguments: [json]) {
			return result.description
		}
		else {
			return json
		}
	}
}
