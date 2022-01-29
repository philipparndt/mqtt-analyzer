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
	let topic: String
	let payload: MsgPayload
	let metadata: MsgMetadata
	
	init(topic: String, payload: MsgPayload, metadata: MsgMetadata) {
		self.topic = topic
		self.payload = payload
		self.metadata = metadata
	}
}

class MessageModel: ObservableObject {
	@Published var filterText = "" {
		didSet {
			updateDisplayTopicsAsync()
		}
	}
	
	@Published var messagesByTopic: [String: MessagesByTopic] {
		didSet {
			updateDisplayTopics()
		}
	}

	@Published var messageCount: Int = 0
		
	@Published var displayTopics: [MessagesByTopic] = []
	
	@Published var topicLimit = false
	@Published var messageLimit = false
	
	var limitMessagesPerBatch = 1000
	var limitTopics: Int = 250
	
	init(messagesByTopic: [String: MessagesByTopic] = [:]) {
		self.messagesByTopic = messagesByTopic
	}
	
	func topicByPath(_ path: Topic) -> [Topic] {
		let nextLevels = displayTopics.map {
			$0.topic.nextLevel(hierarchy: path)
		}
		.filter { $0 != nil }
		.map { $0! }
		.filter {
			filterText.isEmpty || $0.fullTopic.lowercased().contains(filterText.lowercased())
		}
		
		return Array(Set(nextLevels)).sorted { $0.name < $1.name }
	}
	
	func displayTopics(by path: Topic, maxBeforeCollapse: Int? = 10) -> [MessagesByTopic] {
		let result = displayTopics
			.filter {
				$0.topic.segments.starts(with: path.segments)
			}
		
		if maxBeforeCollapse != nil && result.count > maxBeforeCollapse! {
			return result.filter { $0.topic.fullTopic == path.fullTopic }
		}
		else {
			return result
		}
	}
	
	func countDisplayTopics(by path: Topic) -> Int {
		return displayTopics(by: path, maxBeforeCollapse: nil).count
	}
	
	func countDisplayMessages(by path: Topic) -> Int {
		return displayTopics(by: path, maxBeforeCollapse: nil)
			.map { $0.messages.count }
			.reduce(0, +)
	}
	
	func setFilterImmediatelly(_ filter: String) {
		self.filterText = filter
	}
	
	private func updateDisplayTopics() {
		self.messageCount = countMessages()
		self.displayTopics = self.sortedTopicsByFilter(filter: self.filterText)
	}
	
	private func updateDisplayTopicsAsync() {
		self.updateDisplayTopics()
	}
	
	func sortedTopics() -> [MessagesByTopic] {
		return sortedTopicsByFilter(filter: nil)
	}
	
	func sortedTopicsByFilter(filter: String?) -> [MessagesByTopic] {
		var values = Array(messagesByTopic.values)
			
		values.sort {
			$0.topic.name < $1.topic.name
		}
		
		let trimmedFilter = filter?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		
		if trimmedFilter.isBlank {
			return values
		}
		
		return values.filter {
			let data = $0.getRecentMessage()?.payload.dataString ?? ""
			return $0.topic.name.localizedCaseInsensitiveContains(trimmedFilter)
			|| data.localizedCaseInsensitiveContains(trimmedFilter)
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
