//
//  TopicModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class Topic: Hashable, Identifiable {
	let id: String
	let name: String
	let lastSegment: String

	init(_ name: String) {
		self.name = name
		self.id = name
		self.lastSegment = Topic.lastSegment(of: name)
	}

	func nextLevel(hierarchy: Topic) -> Topic? {
		if name.count == hierarchy.name.count {
			return nil
		}
		
		if name.starts(with: hierarchy.name) {
			let startIndex = name.index(name.startIndex, offsetBy: hierarchy.name.count + (hierarchy.name.isEmpty ? 0 : 1))
			let sub = name[startIndex...]
			let index = sub.firstIndex(of: "/")
				.map { $0.utf16Offset(in: sub) }
				.map { $0 - 1}
			
			if index == nil {
				return self
			}
			
			let endIndex = name.index(startIndex, offsetBy: index!)
			return Topic(String(name[...endIndex]))
		}
		
		return nil
	}
	
	class func lastSegment(of: String) -> String {
		let index = of.lastIndex(of: "/")
			.map { $0.utf16Offset(in: of) }
			.map { $0 + 1 }
		
		return String(of.dropFirst(index ?? 0))
	}
	
	static func == (lhs: Topic, rhs: Topic) -> Bool {
		return lhs.name == rhs.name
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
