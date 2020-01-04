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

class MessagesByTopic: Identifiable, ObservableObject {
	let topic: Topic
	
	@Published var read: Readstate = Readstate()
	@Published var messages: [Message]
	@Published var timeSeries = Multimap<DiagramPath, TimeSeriesValue>()
	@Published var timeSeriesModels = [DiagramPath: MTimeSeriesModel]()
	
	var willChange = PassthroughSubject<Void, Never>()
	
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
		
		if message.isJson() {
			let jsonData = message.jsonData!
			if !jsonData.isEmpty {
				traverseJson(node: message.jsonData!, path: "", dateFormatted: message.localDate)
			}
		}
		
		messages.insert(message, at: 0)
	}
	
	func traverseJson(node: [String: Any], path: String, dateFormatted: String) {
		print(node)
		
		node.forEach {
			let child = $0.value
			if child is [String: Any] {
				let nextPath = path + $0.key
				traverseJson(node: child as! [String: Any], path: nextPath + ".", dateFormatted: dateFormatted)
			}
		}

		node.filter { $0.value is NSNumber }
			.forEach {
				let path = DiagramPath(path + $0.key)
				let value: NSNumber = $0.value as! NSNumber
				
				self.timeSeries.put(key: path, value: TimeSeriesValue(value: value, at: Date(), dateFormatted: dateFormatted))
				
				let val = MTimeSeriesValue(value: value, timestamp: Date())
				if let existingValues = self.timeSeriesModels[path] {
					existingValues.values.append(val)
					self.timeSeriesModels[path] = existingValues
				} else {
					let model = MTimeSeriesModel()
					model.values.append(val)
					self.timeSeriesModels[path] = model
				}
			}
	}
	
	func getFirst() -> String {
		return messages.isEmpty ? "<undef>" : messages[0].data
	}
	
	func getFirstMessage() -> Message? {
		return messages.isEmpty ? nil : messages[0]
	}
	
	func getDiagrams() -> [DiagramPath] {
		return Array(timeSeries.dict.keys)
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
	
	func getTimeSeriesInt(_ path: DiagramPath) -> [Int] {
		return getTimeSeries(path).map { $0.num.intValue }
	}
	
	func getTimeSeriesId(_ path: DiagramPath) -> [TimeSeriesValue] {
		return getTimeSeries(path)
	}
	
	func getValuesLastHour(_ path: DiagramPath) -> [Int] {
		if let model = self.timeSeriesModels[path] {
			let values = model.getMeanValue(amount: 30, in: 30, to: Date())
				.map { $0.meanValue ?? 0 }
			
//			let minValue = values.filter {$0 != 0} .min() ?? 0
//			return values
//				.map { $0 == 0 ? 1 : $0 - minValue }
			
			return values
		} else {
			return [Int]()
		}
	}
}
