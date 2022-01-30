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
		var result = children.values.flatMap { $0.recusiveAllMessages }
		result.append(self)
		
		return result
			.filter { !$0.messages.isEmpty }
			.sorted { $0.nameQualified < $1.nameQualified }
	}
	
	var childrenWithMessages: [TopicTree] {
		return children.values.filter {
			!$0.messages.isEmpty
		}
		.sorted { $0.nameQualified < $1.nameQualified }
	}
}
