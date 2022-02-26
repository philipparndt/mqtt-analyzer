//
//  TopicTreeFilterExt.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

struct SearchResult: Identifiable {
	let id = UUID()
	let topic: String
}

extension TopicTree {
	func updateChildrenToDisplay() {
		return childrenDisplay = Array(children.values)
	}
	
	func updateSearchResult() {
		if filterTextCleaned.isBlank {
			searchResultDisplay = []
			return
		}
		
		searchResultDisplay = search(text: filterTextCleaned)
			.map {
				if let topic = addTopic(topic: $0) {
					return topic
				}
				return nil
			}
			.filter { $0 != nil }
			.map { $0! }
	}
	
}
