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
		
//		if let json = message.payload.jsonData {
//			collectValues(date: message.metadata.date, json: json, path: [], dateFormatted: message.metadata.localDate)
//		}
		
		messages.insert(message, at: 0)
	}
	
	func getRecent() -> String {
		return messages.isEmpty ? "<undef>" : messages[0].payload.dataString
	}
	
	func getRecentMessage() -> Message? {
		return messages.isEmpty ? nil : messages[0]
	}

}
