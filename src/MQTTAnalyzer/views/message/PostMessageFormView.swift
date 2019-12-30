//
//  PostMessageFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

enum PostMessagePropertyType {
	case boolean
	case integer
	case text
}

class PostMessagePropertyValue {
	var valueText: String
	var valueBool: Bool
	
	init(value: Any) {
		if let v = value as? String {
			self.valueText = v
			self.valueBool = false
		}
		else if let v = value as? Bool {
			self.valueText = ""
			self.valueBool = v
		}
		else {
			self.valueText = ""
			self.valueBool = false
		}
	}
	
	func type() -> PostMessagePropertyType {
		return .text
	}
}

class PostMessagePropertyValueBoolean: PostMessagePropertyValue {
	override func type() -> PostMessagePropertyType {
		return .boolean
	}
}

class PostMessagePropertyValueInteger: PostMessagePropertyValue {
	override func type() -> PostMessagePropertyType {
		return .integer
	}
}

class PostMessagePropertyValueText: PostMessagePropertyValue {
}

struct PostMessageProperty: Identifiable {
	let id: String = NSUUID().uuidString
	let name: String
	let path: [String]
	var value: PostMessagePropertyValue
}

class PostMessageFormModel {
	var topic: String = "/"
    var message: String = ""
    var qos: Int = 0
	var retain: Bool = false
	var json: Bool = false
	var jsonData: [String: Any]?
	var properties: [PostMessageProperty] = []
	
	class func of(message: Message, topic: Topic) -> PostMessageFormModel {
		let model = PostMessageFormModel()
		model.message = message.data
		model.topic = topic.name
		model.qos = Int(message.qos)
		model.retain = message.retain
		model.json = message.isJson()
		model.jsonData = message.jsonData
		
		if message.isJson() {
			let data = message.jsonData!
			print(data)
			print(message.json(jsonData: data)?.prettyPrintedJSONString ?? "{}")
			
			var properties: [PostMessageProperty] = []
			PostMessageFormModel.createJsonProperties(json: data, path: [], properties: &properties)
			
			properties.forEach { model.properties.append($0) }
		}
		
		return model
	}
	
	func updateMessageFromJsonData() {
		if var data = jsonData {
			for property in properties {
				if property.value is PostMessagePropertyValueBoolean {
					let path = property.path
					// TODO: Lookup path
					data[path[0]] = property.value.valueBool
				}
				else if property.value is PostMessagePropertyValueText {
					let path = property.path
					// TODO: Lookup path
					data[path[0]] = property.value.valueText
				}
				else if property.value is PostMessagePropertyValueInteger {
					let path = property.path
					// TODO: Lookup path
					data[path[0]] = Int(property.value.valueText)
				}
			}
			
			self.message = serializeJson(data: data)
		}
	}
	
	func serializeJson(data: [String: Any]) -> String {
		// swiftlint:disable force_try
		return try! JSONSerialization.data(withJSONObject: data).printedJSONString ?? "{}"
	}
	
	class func createJsonProperties(json: [String: Any], path: [String], properties: inout [PostMessageProperty]) {
        json.forEach {
            let child = $0.value
            if child is [String: Any] {
                var nextPath = path
				nextPath.append($0.key)
				
                createJsonProperties(json: child as! [String: Any], path: nextPath, properties: &properties)
            }
        }
		
		json.filter { $0.value is Bool }
		.forEach {
			var propertyPath = path
			propertyPath.append($0.key)
			let property = PostMessageProperty(name: $0.key, path: propertyPath, value: PostMessagePropertyValueBoolean(value: $0.value))
			properties.append(property)
		}
		
		json.filter { $0.value is String }
		.forEach {
			var propertyPath = path
			propertyPath.append($0.key)
			let property = PostMessageProperty(name: $0.key, path: propertyPath, value: PostMessagePropertyValueText(value: $0.value))
			properties.append(property)
		}
		
		json.filter { $0.value is Int }
			.filter { !($0.value is Bool) }
		.forEach {
			var propertyPath = path
			propertyPath.append($0.key)
			let property = PostMessageProperty(name: $0.key, path: propertyPath, value: PostMessagePropertyValueInteger(value: "\($0.value)"))
			properties.append(property)
		}
	}
}

struct PostMessageFormModalView: View {
    @Binding var isPresented: Bool
    let root: RootModel
	@State var model: PostMessageFormModel
    
    var body: some View {
        NavigationView {
            PostMessageFormView(message: $model)
                .font(.caption)
                .navigationBarTitle(Text("Post message"))
                .navigationBarItems(
                    leading: Button(action: cancel) {
                        Text("Cancel")
                        
                    }.buttonStyle(ActionStyleLeading()),
                    trailing: Button(action: post) {
                        Text("Post")
                    }.buttonStyle(ActionStyleTrailing())
            )
        }
    }
    
    func post() {
		model.updateMessageFromJsonData()
		
		let msg = Message(data: model.message,
						  date: Date.init(),
						  qos: Int32(model.qos), retain: model.retain)
		root.post(topic: Topic(model.topic), msg)
		self.isPresented = false
    }
    
    func cancel() {
        self.isPresented = false
    }
}

struct PostMessageFormView: View {
	@Binding var message: PostMessageFormModel
    
    var body: some View {
		Form {
			Section(header: Text("Topic")) {
				TextField("#", text: $message.topic)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.font(.body)
			}

			if message.json {
				PostMessageFormJSONView(message: $message)
			}
			else {
				PostMessageFormPlainTextView(message: $message.message)
			}
			
			QOSSectionView(qos: $message.qos)

			Spacer().frame(height: 300) // Keyboard scoll spacer
		}
    }
}

struct PostMessageFormPlainTextView: View {
	@Binding var message: String
    
    var body: some View {
		Section(header: Text("Message")) {
			MessageTextView(text: $message)
			.disableAutocorrection(true)
			.autocapitalization(.none)
			.font(.system(.body, design: .monospaced))
			.frame(height: 250)
		}
    }
}

struct PostMessageFormJSONView: View {
	@Binding var message: PostMessageFormModel
    
    var body: some View {
		Section(header: Text("Properties")) {
			ForEach(message.properties.indices) { index in
				HStack {
					Text(self.message.properties[index].name)
					Spacer()
					MessageProperyView(property: self.$message.properties[index])
				}
//				Section(header: Text(self.message.properties[index].name)) {
//					MessageProperyView(property: self.$message.properties[index])
//				}
			}
		}
    }
}

struct MessageProperyView: View {
	@Binding var property: PostMessageProperty
    
    var body: some View {

		HStack {
			if property.value is PostMessagePropertyValueBoolean {
				Toggle("", isOn: self.$property.value.valueBool)
			}
			else if property.value is PostMessagePropertyValueText {
				TextField("", text: self.$property.value.valueText)
				.disableAutocorrection(true)
				.multilineTextAlignment(.trailing)
				.autocapitalization(.none)
				.font(.body)
			}
			else if property.value is PostMessagePropertyValueInteger {
				TextField("", text: self.$property.value.valueText)
				.disableAutocorrection(true)
				.multilineTextAlignment(.trailing)
				.autocapitalization(.none)
				.font(.body)
			}
			else {
				Text("Unknown property type")
			}
		}
    }
}
