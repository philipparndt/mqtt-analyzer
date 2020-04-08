//
//  MessageModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

class Message: Identifiable {
	var jsonData: JSON?
	
	let data: String
	let date: Date
	let localDate: String
	let qos: Int32
	let retain: Bool
	let topic: String
	
	init(data: String, date: Date, qos: Int32, retain: Bool, topic: String) {
		self.data = data
		self.date = date
		self.qos = qos
		self.jsonData = Message.toJson(messageData: data)
		self.retain = retain
		self.topic = topic
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		self.localDate = dateFormatter.string(from: date)
	}
	
	func isJson() -> Bool {
		return jsonData != nil
	}
	
	func prettyJson() -> String {
		return jsonData?.rawString() ?? "{}"
	}
	
	class func toJson(messageData: String) -> JSON? {
		let json = JSON(parseJSON: messageData)
		if json.isEmpty {
			return nil
		}
		else {
			return json
		}
	}
	
	class func cleanEscapedNumbers(_ messageData: String) -> String {
		return messageData.replacingOccurrences(of: "[\"'](-?[1-9]+\\d*)[\"']",
		with: "$1",
		options: .regularExpression)
	}
}

class MessageModel: QuickFilterTextDebounce, ObservableObject {
	@Published var messagesByTopic: [String: MessagesByTopic] {
		didSet {
			updateDisplayTopics()
		}
	}

	@Published var messageCount: Int = 0
	
	@Published var filter: String = "" {
		didSet {
			updateDisplayTopicsAsync()
		}
	}
	
	override func onChange(text: String) {
		if self.filter != text {
			self.filter = text
		}
	}
	
	@Published var displayTopics: [MessagesByTopic] = []
	
	@Published var topicLimit = false
	@Published var messageLimit = false
	
	var limitMessagesPerBatch = 1000
	var limitTopics: Int = 250
	
	init(messagesByTopic: [String: MessagesByTopic] = [:]) {
		self.messagesByTopic = messagesByTopic
	}
	
	func setFilterImmediatelly(_ filter: String) {
		self.filter = filter
		self.filterText = filter
	}
	
	private func updateDisplayTopics() {
		self.messageCount = countMessages()
		self.displayTopics = self.sortedTopicsByFilter(filter: self.filter)
	}
	
	private func updateDisplayTopicsAsync() {
		// MARK: done this due to performance reasons
		// otherwise SwiftUI will trigger a repaint for each changed element
		self.displayTopics = []
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
			self.updateDisplayTopics()
		}
	}
	
	func sortedTopics() -> [MessagesByTopic] {
		return sortedTopicsByFilter(filter: nil)
	}
	
	func sortedTopicsByFilter(filter: String?) -> [MessagesByTopic] {
		var values = Array(messagesByTopic.values)
			
		values.sort {
			$0.topic.name < $1.topic.name
		}
			   
		return values.filter {
			let trimmed = filter?.trimmingCharacters(in: .whitespacesAndNewlines)
			
			return trimmed == nil || trimmed!.isBlank || $0.topic.name.localizedCaseInsensitiveContains(trimmed!)
		}
	}
	
	func readall() {
		messagesByTopic.values.forEach { $0.read.markRead() }
	}
	
	func clear() {
		messagesByTopic = [:]
	}
	
	func countMessages() -> Int {
		return messagesByTopic.values.map { $0.messages.count }.reduce(0, +)
	}
	
	func append(message: Message) {
		var msgbt = messagesByTopic[message.topic]
		
		if msgbt == nil {
			if messagesByTopic.count >= limitTopics {
				topicLimit = true
				return
			}
			
			msgbt = MessagesByTopic(topic: Topic(message.topic), messages: [])
			messagesByTopic[message.topic] = msgbt
		}
		
		msgbt!.newMessage(message)
		self.messageCount = countMessages()
		updateDisplayTopics()
	}
	
	func append(messages: [Message]) {
		if messages.count > limitMessagesPerBatch {
			// Message limit per batch
			messageLimit = true
			return
		}
		
		messages.forEach {
			self.append(message: $0)
		}
	}
}
