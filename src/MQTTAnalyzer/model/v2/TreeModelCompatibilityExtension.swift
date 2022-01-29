//
//  TreeModelCompatibilityExtension.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var childrenList: [TopicTree] {
		return Array(children.values)
	}
	
	var childrenWithMessages: [TopicTree] {
		return Array(children.values.filter {
			!$0.messages.isEmpty
		})
	}
	
	var filterText: String {
		get {
			return ""
		}
		
		set {
			
		}
	}
	
	var topicLimit: Bool {
		return false
	}

	var messageLimit: Bool {
		return false
	}
	
	var read: Readstate {
		return Readstate()
	}
	
	var displayTopics: String {
		return ""
	}
	
	func readall() {
		
	}
	
	func clear() {
		
	}
	
	func delete(at offsets: IndexSet) {
		
	}
	
	func hasDiagrams() -> Bool {
		return false
	}
}
