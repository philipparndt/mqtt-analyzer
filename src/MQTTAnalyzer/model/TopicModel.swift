//
//  TopicModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class Topic: Hashable {
	let name: String
	let lastSegment: String

	init(_ name: String) {
		self.name = name
		self.lastSegment = Topic.lastSegment(of: name)
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
