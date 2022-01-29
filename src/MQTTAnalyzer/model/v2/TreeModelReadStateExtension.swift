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
		
		let result = childrenList
			.map { $0.readStateCombined }
			.contains { !$0 }
		
		return result
	}
	
	func markRead() {
		readState.markRead()
		
		for child in childrenList {
			child.markRead()
		}
	}
	
	func markUnread() {
		readState.markUnread()
		
//		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//			self.markRead()
//		}
		
		var current: TopicTree? = parent
		while current != nil {
			current?.readState.markUnread()
			current = current?.parent
		}
	}
}
