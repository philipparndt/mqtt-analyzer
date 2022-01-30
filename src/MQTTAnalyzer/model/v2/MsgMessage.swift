//
//  MsgMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class MsgMessage: Identifiable {
	let topic: TopicTree
	let payload: MsgPayload
	let metadata: MsgMetadata
	
	init(topic: TopicTree, payload: MsgPayload, metadata: MsgMetadata) {
		self.topic = topic
		self.payload = payload
		self.metadata = metadata
	}
}
