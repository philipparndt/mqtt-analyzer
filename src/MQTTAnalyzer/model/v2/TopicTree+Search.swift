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
			_ = idx.add(message: message)
		}
	}
	
	func search(text: String) -> [String] {
		if let idx = getIndex() {
			let topic = nameQualified
			
			return idx.search(text: text)
				.filter {
					$0.starts(with: topic)
				}
		}
		
		return []
	}
}
