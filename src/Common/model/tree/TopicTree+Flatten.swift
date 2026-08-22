//
//  TreeModelCompatibilityExtension.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var recusiveAllMessages: [TopicTree] {
		if let cached = flatMessageNodes {
			return cached
		}

		var result = children.values.flatMap { $0.recusiveAllMessages }
		result.append(self)

		let nodes = result
			.filter { !$0.messages.isEmpty }
			.sorted { $0.nameQualified < $1.nameQualified }

		flatMessageNodes = nodes
		return nodes
	}

	var childrenWithMessages: [TopicTree] {
		return children.values.filter {
			!$0.messages.isEmpty
		}
		.sorted { $0.nameQualified < $1.nameQualified }
	}

}
