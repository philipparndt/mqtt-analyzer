//
//  PublishMessageModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-06-27.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

enum TopicSuffix: String, CaseIterable {
	case none = ""
	case sset = "/set"
	case sget = "/get"
	case sstate = "/state"
}

class PublishMessageFormModel: ObservableObject {
	@Published var isPresented = false
	@Published var message: String = ""
	@Published var qos: Int = 2
	@Published var retain: Bool = false
	@Published var messageType: PublishMessageType = .plain
	@Published var properties: [PublishMessageProperty] = []

	var jsonData: Any?

	private var _topicSuffix: TopicSuffix = .none
	var topicSuffix: TopicSuffix {
		get {
			return _topicSuffix
		}

		set {
			objectWillChange.send()
			var newTopic = topic
			for suffix in TopicSuffix.allCases where newTopic.hasSuffix(suffix.rawValue) {
				newTopic = String(newTopic.dropLast(suffix.rawValue.count))
			}

			newTopic = String(newTopic + newValue.rawValue)

			_topicSuffix = newValue
			_topic = newTopic
		}
	}

	private var _topic: String = ""
	var topic: String {
		get {
			return _topic
		}

		set {
			objectWillChange.send()
			for suffix in TopicSuffix.allCases where newValue.hasSuffix(suffix.rawValue) {
				_topicSuffix = suffix
			}
			_topic = newValue
		}
	}

	func updateMessageFromJsonData() {
		if var json = jsonData {
			for property in properties {
				json = PublishMessageFormModel.setNestedValue(in: json, at: property.path, value: property.value.getTypedValue())
			}

			if let data = try? JSONSerialization.data(withJSONObject: json, options: []),
			   let message = String(data: data, encoding: .utf8) {
				self.message = message
			}
		}
	}

	private static func setNestedValue(in object: Any, at path: [String], value: Any) -> Any {
		guard !path.isEmpty else { return value }
		var dict = (object as? [String: Any]) ?? [:]
		if path.count == 1 {
			dict[path[0]] = value
		} else {
			dict[path[0]] = setNestedValue(in: dict[path[0]] ?? [String: Any](), at: Array(path.dropFirst()), value: value)
		}
		return dict
	}
}

func of(message: MsgMessage) -> PublishMessageFormModel {
	let model = PublishMessageFormModel()
	model.message = message.payload.dataString
	model.topic = message.topic.nameQualified
	model.qos = Int(message.metadata.qos)
	model.retain = message.metadata.retain
	model.messageType = message.payload.isJSON ? .json : .plain

	if let json = message.payload.jsonData {
		model.jsonData = json

		createJsonProperties(json: json, path: [])
			.sorted(by: { $0.pathName < $1.pathName })
			.forEach { model.properties.append($0) }
	}

	return model
}

func createJsonProperties(json: Any, path: [String]) -> [PublishMessageProperty] {
	var result: [PublishMessageProperty] = []
	if let dict = json as? [String: Any] {
		for (key, child) in dict {
			result += createJsonProperties(json: child, path: path + [key])
		}
	}

	if let property = createProperty(json: json, path: path) {
		result += [property]
	}

	return result
}

func createProperty(json: Any, path: [String]) -> PublishMessageProperty? {
	if path.isEmpty {
		return nil
	}

	let name = path[path.count - 1]
	let pathName = path.joined(separator: ".")

	if let value = json as? Bool {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path,
								   value: PublishMessagePropertyValueBoolean(value: value))
	}
	else if let str = json as? String {
		let lower = str.lowercased()
		if lower == "on" || lower == "off" {
			return PublishMessageProperty(name: name, pathName: pathName,
									   path: path,
									   value: PublishMessagePropertyValueOnOff(value: lower == "on"))
		}
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueText(value: str))
	}
	else if let value = json as? Int {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueNumber(value: "\(value)"))
	}
	else if let value = json as? Double {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueNumber(value: "\(value)"))
	}
	else {
		return nil
	}
}
