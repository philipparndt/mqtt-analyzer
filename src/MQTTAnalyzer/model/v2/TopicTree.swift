//
//  TreeModel.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class TopicTree: Identifiable, ObservableObject {
	let id = UUID()
	let name: String
	var nameQualified: String {
		return TopicTree.toQualifiedName(node: self)
	}

	let parent: TopicTree?
	
	var children: [String: TopicTree] = [:] {
		didSet {
			updateChildrenToDisplay()
			updateMessageCount()
		}
	}

	var totalTopicCounter = 0
	
	@Published var messageCountDisplay: Int = 0
	@Published var topicCountDisplay: Int = 0
	@Published var childrenDisplay: [TopicTree] = []
	@Published var messages: [MsgMessage] = []
	@Published var timeSeries = TimeSeriesModel()
	@Published var readState = Readstate()
	
	@Published var topicLimitExceeded = false
	@Published var messageLimitExceeded = false

	var filterTextCleaned = ""
	@Published var filterText = "" {
		didSet {
			filterTextCleaned = filterText.trimmingCharacters(in: [" "]).lowercased()
			updateChildrenToDisplay()
		}
	}
	
	init() {
		self.name = "root"
		self.parent = nil
	}
	
	init(name: String, parent: TopicTree? = nil) {
		self.name = name
		self.parent = parent
		self.parent?.children[name] = self
	}
	
	private func addMessage(message: MsgMessage) {
		messages.insert(message, at: 0)
		markUnread()
		
		childrenDisplay = Array(children.values.sorted { $0.name < $1.name })
		updateMessageCount()
		 
		if let json = message.payload.jsonData {
			timeSeries.collect(
				date: message.metadata.date,
				json: json,
				path: [],
				dateFormatted: message.metadata.localDate
			)
		}
	}
	
	private func updateMessageCount() {
		messageCountDisplay = messageCount
		topicCountDisplay = topicCount
		
		// Propagate new message counter
		parent?.updateMessageCount()
	}
}

extension TopicTree {
	class func toQualifiedName(node: TopicTree) -> String {
		var next = node.parent
		var result = node.name
		while next != nil && next?.parent != nil {
			result = next!.name
				.appending("/")
				.appending(result)
			next = next?.parent
		}
		return result
	}
	
	func findRoot() -> TopicTree {
		var result = self
		while result.parent != nil {
			result = result.parent!
		}
		return result
	}
	
	func addTopic(topic: String) -> TopicTree? {
		let segments = topic.split(separator: "/").map { String($0) }
		
		var current = findRoot()
				
		for pos in 0..<segments.count {
			let name = segments[pos]
			var next = current.children[name]
			if next == nil {
				if topicLimitExceeded {
					return nil
				}
				
				next = TopicTree(name: name, parent: current)
				
				totalTopicCounter += 1
			}
			current = next!
		}
		
		return current
	}
	
	func addMessage(metadata: MsgMetadata, payload: MsgPayload, to topic: String) -> MsgMessage? {
		if let node = addTopic(topic: topic) {
			let message = MsgMessage(topic: node, payload: payload, metadata: metadata)
			node.addMessage(message: message)
			return message
		}
		else {
			return nil
		}
	}
}
