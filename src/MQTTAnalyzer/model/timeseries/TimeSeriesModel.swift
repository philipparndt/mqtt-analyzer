//
//  TimeSeriesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-05.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

struct MTimeSeriesValue {
	let value: NSNumber
	let timestamp: Date
}

struct MTimeSeriesMeanValue {
	let meanValue: Int?
}

class TimeSeriesValue: Hashable, Identifiable {
	let num: NSNumber
	var numString: String {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.locale = Locale(identifier: "en")
		return formatter.string(from: num) ?? ""
	}

	let date: Date
	let dateString: String
	
	init(value num: NSNumber, at date: Date, dateFormatted: String) {
		self.num = num
		self.date = date
		self.dateString = dateFormatted
	}
	
	static func == (lhs: TimeSeriesValue, rhs: TimeSeriesValue) -> Bool {
		return lhs.num == rhs.num
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(num)
	}
}

class DiagramPath: Hashable, Identifiable {
	let path: String
	
	init(_ path: String) {
		self.path = path
	}
	
	static func == (lhs: DiagramPath, rhs: DiagramPath) -> Bool {
		return lhs.path == rhs.path
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(path)
	}
}

class MTimeSeriesModel {
	var values: [MTimeSeriesValue] = []
}
