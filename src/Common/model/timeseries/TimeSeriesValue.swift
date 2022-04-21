//
//  TimeSeriesValue.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

class TimeSeriesValue: Hashable, Identifiable {
	let value: AnyHashable
	let valueString: String
	
	let date: Date
	let dateString: String
	
	init(value: AnyHashable, at date: Date, dateFormatted: String) {
		self.value = value
		self.valueString = TimeSeriesValueUtil.createStringValue(value: value)
		self.date = date
		self.dateString = dateFormatted
	}
	
	static func == (lhs: TimeSeriesValue, rhs: TimeSeriesValue) -> Bool {
		return lhs.value == rhs.value
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(valueString)
	}
}
