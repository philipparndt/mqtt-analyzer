//
//  TreeModelDeleteExtension.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	func clear() {
		children = [:]
		messageCountDisplay = 0
		totalTopicCounter = 0
		topicCountDisplay = 0
		childrenDisplay = []
		messages = []
		timeSeries = TimeSeriesModel()
		readState = Readstate(read: true)
		index?.clear(topicStartsWith: nameQualified)
		topicLimitExceeded = false
	}
	
	func delete(at offsets: IndexSet) {
		messages.remove(atOffsets: offsets)
	}
	
	func delete(message: MsgMessage) {
		if let index = messages.firstIndex(of: message) {
			messages.remove(at: index)
		}
		
		var node: TopicTree? = self
		while node != nil {
			let current = node!
			current.messageCountDirty = true

			node = current.parent
		}
	}
}
