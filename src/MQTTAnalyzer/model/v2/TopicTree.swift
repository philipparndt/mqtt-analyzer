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
	let index: SearchIndex?
	
	var children: [String: TopicTree] = [:] {
		didSet {
			updateSearchResult()
			updateChildrenToDisplay()
			updateMessageCount()
		}
	}

	var totalTopicCounter = 0
	
	@Published var messageCountDisplay: Int = 0
	@Published var topicCountDisplay: Int = 0
	@Published var childrenDisplay: [TopicTree] = [] {
		didSet {
			if childrenDisplay.isEmpty && messages.isEmpty {
				readState = Readstate(read: true)
			}
		}
	}
	@Published var searchResultDisplay: [TopicTree] = [] {
		didSet {
			if childrenDisplay.isEmpty && messages.isEmpty {
				readState = Readstate(read: true)
			}
		}
	}
	@Published var messages: [MsgMessage] = [] {
		didSet {
			parent?.recomputeReadState()
		}
	}
	@Published var timeSeries = TimeSeriesModel()
	@Published var readState = Readstate(read: false) {
		didSet {
			if readState.read {
				parent?.recomputeReadState()
			}
		}
	}
	
	@Published var topicLimitExceeded = false
	@Published var messageLimitExceeded = false

	@Published var flatView = false
	
	@Published var filterWholeWord = true {
		didSet {
			updateSearchResult()
		}
	}
	
	var filterTextCleaned = ""
	@Published var filterText = "" {
		didSet {
			filterTextCleaned = filterText.trimmingCharacters(in: [" "]).lowercased()
			updateChildrenToDisplay()
			updateSearchResult()
		}
	}
	
	init() {
		self.name = "root"
		self.parent = nil
		self.index = SearchIndex()
	}
	
	init(name: String, parent: TopicTree? = nil) {
		self.name = name
		self.parent = parent
		self.index = nil
		
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
		var result = next != nil ? node.name : ""
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
	
	func getTopic(topic: String) -> TopicTree? {
		return addTopic(topic: topic, create: false)
	}
	
	func addTopic(topic: String, create: Bool = true) -> TopicTree? {
		let segments = topic.split(separator: "/", omittingEmptySubsequences: false).map { String($0) }
		
		var current = findRoot()
		var created = false
				
		for pos in 0..<segments.count {
			let name = segments[pos]
			var next = current.children[name]
			if next == nil {
				if topicLimitExceeded || !create {
					return nil
				}
				
				next = TopicTree(name: name, parent: current)
				
				created = true
			}
			current = next!
		}

		if created {
			totalTopicCounter += 1
		}
		
		return current
	}
	
	func addMessage(metadata: MsgMetadata, payload: MsgPayload, to topic: String) -> MsgMessage? {
		if let node = addTopic(topic: topic) {
			let message = MsgMessage(topic: node, payload: payload, metadata: metadata)
			node.addMessage(message: message)
			
			addToIndex(message: message)
			return message
		}
		else {
			return nil
		}
	}
}
