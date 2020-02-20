//
//  MessagesByTopic.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import SwiftyJSON

class MessagesByTopic: Identifiable, ObservableObject {
	let topic: Topic
	
	@Published var read: Readstate = Readstate()
	@Published var messages: [Message]
	@Published var timeSeries = Multimap<DiagramPath, TimeSeriesValue>()
	@Published var timeSeriesModels = [DiagramPath: MTimeSeriesModel]()
	
	init(topic: Topic, messages: [Message]) {
		self.topic = topic
		self.messages = messages
	}

	func clear() {
		messages = []
	}
	
	func delete(at offsets: IndexSet) {
		messages.remove(atOffsets: offsets)
	}

	func newMessage(_ message: Message) {
		read.markUnread()
		
		if let json = message.jsonData {
			collectValues(date: message.date, json: json, path: [], dateFormatted: message.localDate)
		}
		
		messages.insert(message, at: 0)
	}
	
	func collectValues(date: Date, json: JSON, path: [String], dateFormatted: String) {
		json.dictionaryValue
		.forEach {
			let child = $0.value
			var nextPath = path
			nextPath += [$0.key]
			
			collectValues(date: date, json: child, path: nextPath, dateFormatted: dateFormatted)
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
	
	func getRecent() -> String {
		return messages.isEmpty ? "<undef>" : messages[0].data
	}
	
	func getRecentMessage() -> Message? {
		return messages.isEmpty ? nil : messages[0]
	}
	
	func getDiagrams() -> [DiagramPath] {
		return Array(timeSeries.dict.keys).sorted { $0.path < $1.path }
	}
	
	func hasDiagrams() -> Bool {
		return !timeSeries.dict.isEmpty
	}
	
	func getTimeSeriesLastValue(_ path: DiagramPath) -> TimeSeriesValue? {
		let values = timeSeries.dict[path] ?? [TimeSeriesValue]()
		return values.last
	}
	
	func getTimeSeries(_ path: DiagramPath) -> [TimeSeriesValue] {
		return timeSeries.dict[path] ?? [TimeSeriesValue]()
	}
	
	func getTimeSeriesId(_ path: DiagramPath) -> [TimeSeriesValue] {
		return getTimeSeries(path)
	}
}
