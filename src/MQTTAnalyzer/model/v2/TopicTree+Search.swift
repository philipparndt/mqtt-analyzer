//
//  MessageCounter.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	func getIndex() -> SearchIndex? {
		var current: TopicTree? = self
		
		while current != nil {
			if let idx = current?.index {
				return idx
			}
			current = current?.parent
		}
		
		return nil
	}
	
	func addToIndex(message: MsgMessage) {
		if let idx = getIndex() {
			idx.add(message: message, completion: {
				message.topic.parent?.updateSearchResult()
			})
		}
	}
	
	func search(text: String) -> [String] {
		if let idx = getIndex() {
			let topic = nameQualified
			var searchText = text
			if !filterWholeWord && !searchText.contains("*") {
				searchText += "*"
			}
			
			return idx.search(text: searchText, topic: topic)
		}
		
		return []
	}
}
