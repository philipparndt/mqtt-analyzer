//
//  TreeModel.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftyJSON

class MsgPayload {
	let data: [UInt8]
	var jsonData: JSON?
	var isJSON: Bool {
		return jsonData != nil
	}
	var isBinary: Bool {
		return dataStringCache == nil
	}
	
	private let dataStringCache: String?
	var dataString: String {
		return dataStringCache ?? "[\(data.count) bytes]"
	}

	init(data: [UInt8]) {
		self.data = data
		self.dataStringCache = MsgPayload.toOptionalString(data: data)
		self.jsonData = MsgPayload.toJson(str: dataStringCache)
	}
}

extension MsgPayload {
	var prettyJSON: String {
		return dataStringCache != nil ? JSONUtils.format(json: dataStringCache!) : ""
	}
}

extension MsgPayload {
	class func toJson(str: String?) -> JSON? {
		if str == nil {
			return nil
		}
		
		let json = JSON.init(parseJSON: str!)
		if json.isEmpty {
			return nil
		}
		else {
			return json
		}
	}
	
	class func toOptionalString(data: [UInt8]) -> String? {
		return NSString(bytes: data, length: data.count, encoding: String.Encoding.utf8.rawValue) as String?
	}
}

class MsgMetadata {
	let date: Date
	let localDate: String
	let qos: Int32
	let retain: Bool
	
	init(qos: Int32, retain: Bool) {
		self.date = Date.now
		self.localDate = DateFormatter.iso.string(from: self.date)
		self.qos = qos
		self.retain = retain
	}
}

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

class TopicTree: Identifiable {
	let id = UUID()
	let name: String
	var nameQualified: String {
		return TopicTree.toQualifiedName(node: self)
	}

	let parent: TopicTree?
	var children: [String: TopicTree] = [:]
	
	var messages: [MsgMessage] = []
		
	init() {
		self.name = "root"
		self.parent = nil
	}
	
	init(name: String, parent: TopicTree? = nil) {
		self.name = name
		self.parent = parent
		self.parent?.children[name] = self
	}
}

extension TopicTree {
	class func toQualifiedName(node: TopicTree) -> String {
		var next = node.parent
		var result = node.name
		while next != nil && next?.parent != nil {
			result = next!.name
				.appending("/")
				.appending(result)
			next = next?.parent
		}
		return result
	}
	
	func addTopic(topic: String) -> TopicTree {
		let segments = topic.split(separator: "/").map { String($0) }
		
		var current = self
		for pos in 0..<segments.count {
			let name = segments[pos]
			var next = current.children[name]
			if next == nil {
				next = TopicTree(name: name, parent: current)
			}
			current = next!
		}
		
		return current
	}
	
	func addMessage(metadata: MsgMetadata, payload: MsgPayload, to topic: String) -> MsgMessage {
		
		let node = addTopic(topic: topic)
		let message = MsgMessage(topic: node, payload: payload, metadata: metadata)
		node.messages.append(message)
		return message
	}
}
