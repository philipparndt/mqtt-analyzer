//
//  TimeSeriesValueUtil.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-01.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

class TimeSeriesValueUtil {
	
	static let numberFormatter = TimeSeriesValueUtil.createNumberFormat()
	
	private class func createNumberFormat() -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.locale = Locale(identifier: "en")
		return formatter
	}
	
	class func createStringValue(value: AnyHashable) -> String {
		if let num = value as? NSNumber {
			return numberFormatter.string(from: num) ?? ""
		}
		else if let bool = value as? Bool {
			return "\(bool)"
		}
		else if let s = value as? String {
			return s
		}
		else {
			return "unknown type"
		}
	}
}
