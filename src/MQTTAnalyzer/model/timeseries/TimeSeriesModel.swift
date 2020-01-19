//
//  TimeSeriesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-05.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

struct MTimeSeriesValue {
	let value: AnyHashable
	let timestamp: Date
}

struct MTimeSeriesMeanValue {
	let meanValue: Int?
}

class TimeSeriesValue: Hashable, Identifiable {
	let value: AnyHashable
	var valueString: String {
		if let num = value as? NSNumber {
			let formatter = NumberFormatter()
			formatter.numberStyle = .decimal
			formatter.locale = Locale(identifier: "en")
			return formatter.string(from: num) ?? ""
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

	let date: Date
	let dateString: String
	
	init(value: AnyHashable, at date: Date, dateFormatted: String) {
		self.value = value
		self.date = date
		self.dateString = dateFormatted
	}
	
	static func == (lhs: TimeSeriesValue, rhs: TimeSeriesValue) -> Bool {
		return lhs.value == rhs.value
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(value)
	}
}

class DiagramPath: Hashable, Identifiable {
	let path: String
	var lastSegment: String {
		if let idx = path.lastIndex(of: ".") {
			let start = path.index(after: idx)
			return String(path[start...])
		}
		return path
	}
	
	var parentPath: String {
		if let idx = path.lastIndex(of: ".") {
			let end = path.index(before: idx)
			return String(path[...end])
		}
		return ""
	}
	
	var hasSubpath: Bool {
		return path.contains(".")
	}
	
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
