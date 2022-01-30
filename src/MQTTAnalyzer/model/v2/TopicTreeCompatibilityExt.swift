//
//  TreeModelCompatibilityExtension.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var childrenWithMessages: [TopicTree] {
		return Array(children.values.filter {
			!$0.messages.isEmpty
		})
	}
	
	var displayTopics: String {
		return ""
	}
	
}
