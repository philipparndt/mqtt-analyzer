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
	let segments: [String]
	let lastSegment: String
	let fullTopic: String

	init(_ name: String, segments: [String]? = nil, fullTopic: String? = nil) {
		self.name = name
		self.segments = segments ?? name.split(separator: "/").map { String($0) }
		self.fullTopic = fullTopic ?? name
		self.id = self.name
		self.lastSegment = self.segments.last ?? name
	}

	func nextLevel(hierarchy: Topic) -> Topic? {
		if segments.count == hierarchy.segments.count || hierarchy.segments.count > segments.count {
			return nil
		}
		
		if self.segments.starts(with: hierarchy.segments) {
			let label = self.segments[hierarchy.segments.count]
			return Topic(label,
						 segments: Array(segments[0...hierarchy.segments.count]),
						 fullTopic: segments.joined(separator: "/"))
		}
		
		return nil
	}
		
	static func == (lhs: Topic, rhs: Topic) -> Bool {
		return lhs.name == rhs.name
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
