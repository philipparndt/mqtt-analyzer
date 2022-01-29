//
//  MessageCounter.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var topicCount: Int {
		return (messages.isEmpty ? 0 : 1) + childrenList
			.map { $0.topicCount }
			   .reduce(0, +)
	}
		
	var messageCount: Int {
		return messages.count + childrenList
			.map { $0.messageCount }
			.reduce(0, +)
	}
}
