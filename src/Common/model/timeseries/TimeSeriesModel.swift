//
//  TimeSeriesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-05.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MTimeSeriesValue {
	let value: AnyHashable
	let timestamp: Date
}

struct MTimeSeriesMeanValue {
	let meanValue: Int?
}

class MTimeSeriesModel {
	var values: [MTimeSeriesValue] = []
}

struct GroupedValue: Identifiable {
	let date: Date
	let min: Double
	let max: Double
	let average: Double
	
	var id: Date {
		return date
	}
}

struct NumberValue {
	let date: Date
	let value: Double
}

class TimeSeriesModel: ObservableObject {
	
	@Published var timeSeries = Multimap<DiagramPath, TimeSeriesValue>()
	@Published var timeSeriesModels = [DiagramPath: MTimeSeriesModel]()
	
	var hasTimeseries: Bool {
		!timeSeries.dict.isEmpty
	}
	
	func getDiagrams() -> [DiagramPath] {
		return Array(timeSeries.dict.keys).sorted { $0.path < $1.path }
	}
		
	func getLastValue(_ path: DiagramPath) -> TimeSeriesValue? {
		return (timeSeries.dict[path] ?? [TimeSeriesValue]()).last
	}
	
	func get(_ path: DiagramPath) -> [TimeSeriesValue] {
		return timeSeries.dict[path] ?? [TimeSeriesValue]()
	}
	
	func getId(_ path: DiagramPath) -> [TimeSeriesValue] {
		return get(path)
	}
	
	func getGrouped(_ path: DiagramPath) -> [GroupedValue] {
		let values = get(path).map {
			if let num = $0.value as? NSNumber {
				return NumberValue(date: $0.date, value: num.doubleValue)
			}
			return NumberValue(date: $0.date, value: 0)
		}
		
		let grouped = Dictionary(grouping: values) { value in
			Int(value.date.timeIntervalSince1970 / 60)
		}
		
		return grouped.values.map { value in
			let raw = value.map { $0.value }
			let date = value.first?.date ?? .now
			let average = raw.reduce(0.0, +) / Double(value.count)
			return GroupedValue(
				date: date,
				min: raw.min() ?? 0,
				max: raw.max() ?? 0,
				average: average
			)
		}
		.sorted { $0.date < $1.date }
		.suffix(30)
	}
	
	func collect(date: Date, json: JSON, path: [String], dateFormatted: String) {
		json.dictionaryValue
		.forEach {
			let child = $0.value
			var nextPath = path
			nextPath += [$0.key]
			
			collect(date: date, json: child, path: nextPath, dateFormatted: dateFormatted)
		}
		
		let path = DiagramPath(path.joined(separator: "."))
		if let value = json.rawValue as? AnyHashable {
			self.timeSeries.put(key: path, value: TimeSeriesValue(value: value, at: date, dateFormatted: dateFormatted))
			
			let val = MTimeSeriesValue(value: value, timestamp: date)
			if let existingValues = self.timeSeriesModels[path] {
				existingValues.values += [val]
				self.timeSeriesModels[path] = existingValues
			} else {
				let model = MTimeSeriesModel()
				model.values += [val]
				self.timeSeriesModels[path] = model
			}
		}
	}
}
