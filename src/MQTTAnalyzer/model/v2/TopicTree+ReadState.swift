//
//  TreeModel.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var readStateCombined: Bool {
		if !readState.read {
			return false
		}
		
		let result = children.values
			.map { $0.readStateCombined }
			.contains { !$0 }
		
		return result
	}
	
	func markRead() {
		readState = Readstate(read: true)
		
		for child in children.values {
			child.markRead()
		}
	}
	
	func markUnread() {
		// readState.markUnread()
		readState = Readstate(read: false)
		
		var current: TopicTree? = parent
		while current != nil {
			current?.readState = Readstate(read: false)
			current = current?.parent
		}
	}
	
	func recomputeReadState() {
		if messages.isEmpty && childrenRead() {
			readState = Readstate(read: true)
		}
	}
	
	func childrenRead() -> Bool {
		return !children.values.contains { node in
			return !node.readState.read
		}
	}
}
