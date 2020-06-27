//
//  PublishMessageModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-06-27.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftyJSON
import swift_petitparser

struct PublishMessageFormModel {
	var isPresented = false
	
	var topic: String = ""
	var message: String = ""
	var qos: Int = 0
	var retain: Bool = false
	var jsonData: JSON?
	var properties: [PublishMessageProperty] = []
	
	var messageType: PublishMessageType = .plain
	
	mutating func updateMessageFromJsonData() {
		if var json = jsonData {
			for property in properties {
				json[property.path] = JSON(property.value.getTypedValue())
			}
			
			if let message = json.rawString(options: []) {
				self.message = message
			}
		}
	}
}


func of(message: Message) -> PublishMessageFormModel {
	var model = PublishMessageFormModel()
	model.message = message.data
	model.topic = message.topic
	model.qos = Int(message.qos)
	model.retain = message.retain
	model.messageType = message.isJson() ? .json : .plain
	
	if let json = message.jsonData {
		model.jsonData = json
		
		createJsonProperties(json: json, path: [])
			.sorted(by: { $0.pathName < $1.pathName })
			.forEach { model.properties.append($0) }
	}
	
	return model
}


func createJsonProperties(json: JSON, path: [String]) -> [PublishMessageProperty] {
	var result: [PublishMessageProperty] = []
	json.dictionaryValue
	.forEach {
		let child = $0.value
		result += createJsonProperties(json: child, path: path + [$0.key])
	}
	
	if let property = createProperty(json: json, path: path) {
		result += [property]
	}
	
	return result
}

func createProperty(json: JSON, path: [String]) -> PublishMessageProperty? {
	if path.isEmpty {
		return nil
	}
	
	let name = path[path.count - 1]
	let pathName = path.joined(separator: ".")
	
	let raw = json.rawString() ?? ""
	let isInt = NumbersParser.int().trim().end().accept(raw)
	
	if let value = json.bool {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path,
								   value: PublishMessagePropertyValueBoolean(value: value))
	}
	else if isInt {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueNumber(value: "\(json.intValue)"))
	}
	else if let value = json.double {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueNumber(value: "\(value)"))
	}
	else if let value = json.string {
		return PublishMessageProperty(name: name, pathName: pathName,
								   path: path, value: PublishMessagePropertyValueText(value: value))
	}
	else {
		return nil
	}
}
