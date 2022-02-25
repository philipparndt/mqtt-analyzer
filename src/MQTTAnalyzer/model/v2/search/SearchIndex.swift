//
//  SearchIndex.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-25.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import DSFFullTextSearchIndex

class SearchIndex {
	let index = DSFFullTextSearchIndex()
	let availabe: Bool
	
	init() {
		availabe = index.create(filePath: ":memory:") == .success
	}
	
	func add(message: MsgMessage) -> Bool {
		if !message.payload.isBinary {
			let topic = message.topic.nameQualified
			
			if let url = URL(string: "msg://\(topic)") {
				return index.add(
					url: url,
					text: topic + " " + message.payload.dataString
				) == .success
			}
		}
		
		return false
	}
	
	func search(text: String) -> [String] {
		if let result = index.search(text: text) {
			return result.map {
				let host = $0.host ?? ""
				return "\(host)\($0.path)"
			}
		}
		return []
	}
	
}
