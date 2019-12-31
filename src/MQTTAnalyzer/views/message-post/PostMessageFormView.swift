//
//  PostMessageFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftyJSON

enum PostMessagePropertyType {
	case boolean
	case number
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
	
	func getTypedValue() -> Any {
		return valueText
	}
}

class PostMessagePropertyValueBoolean: PostMessagePropertyValue {
	override func type() -> PostMessagePropertyType {
		return .boolean
	}
	
	override func getTypedValue() -> Any {
		return valueBool
	}
}

class PostMessagePropertyValueNumber: PostMessagePropertyValue {
	override func type() -> PostMessagePropertyType {
		return .number
	}
	
	override func getTypedValue() -> Any {
		return Double(valueText) ?? 0
	}
}

class PostMessagePropertyValueText: PostMessagePropertyValue {
}

struct PostMessageProperty: Identifiable {
	let id: String = NSUUID().uuidString
	let name: String
	let pathName: String
	let path: [JSONSubscriptType]
	var value: PostMessagePropertyValue
}

class PostMessageFormModel {
	var topic: String = "/"
    var message: String = ""
    var qos: Int = 0
	var retain: Bool = false
	var json: Bool = false
	var jsonData: JSON?
	var properties: [PostMessageProperty] = []
	
	class func of(message: Message, topic: Topic) -> PostMessageFormModel {
		let model = PostMessageFormModel()
		model.message = message.data
		model.topic = topic.name
		model.qos = Int(message.qos)
		model.retain = message.retain
		model.json = message.isJson()
		
		if message.isJson() {
			let json = JSON(parseJSON: message.data)
			model.jsonData = json
			
			var properties: [PostMessageProperty] = []
			PostMessageFormModel.createJsonProperties(json: json, path: [], properties: &properties)
			
			properties
				.sorted(by: { $0.pathName < $1.pathName })
				.forEach { model.properties.append($0) }
		}
		
		return model
	}
	
	func updateMessageFromJsonData() {
		if var json = jsonData {
			for property in properties {
				json[property.path] = JSON(property.value.getTypedValue())
			}
			
			if let message = json.rawString(options: []) {
				self.message = message
			}
		}
	}
	
	func serializeJson(data: [String: Any]) -> String {
		// swiftlint:disable force_try
		return try! JSONSerialization.data(withJSONObject: data).printedJSONString ?? "{}"
	}
	
	class func createJsonProperties(json: JSON, path: [String], properties: inout [PostMessageProperty]) {
		json.dictionaryValue
		.forEach {
            let child = $0.value
			var nextPath = path
			nextPath.append($0.key)
			
			createJsonProperties(json: child, path: nextPath, properties: &properties)
        }
		
		if let property = createProperty(json: json, path: path) {
			properties.append(property)
		}
	}
	
	class func createProperty(json: JSON, path: [String]) -> PostMessageProperty? {
		if path.isEmpty {
			return nil
		}
		
		let name = path[path.count - 1]
		let pathName = path.joined(separator: ".")
		if let value = json.bool {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path,
									   value: PostMessagePropertyValueBoolean(value: value))
		}
		else if let value = json.int {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path, value: PostMessagePropertyValueNumber(value: "\(value)"))
		}
		else if let value = json.double {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path, value: PostMessagePropertyValueNumber(value: "\(value)"))
		}
		else if let value = json.string {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path, value: PostMessagePropertyValueText(value: value))
		}
		else {
			return nil
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
//			Section(header: Text("Debug")) {
//				Button(action: debugClear) {
//					Text("Clear Messages")
//				}
//			}
			
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
	
	func debugClear() {
//		self.messagesByTopic.clear()
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
					Text(self.message.properties[index].pathName)
					Spacer()
					MessageProperyView(property: self.$message.properties[index])
				}
			}
		}
    }
}

struct MessageProperyView: View {
	@Binding var property: PostMessageProperty
    
    var body: some View {

		HStack {
			if property.value.type() == .boolean {
				Toggle("", isOn: self.$property.value.valueBool)
			}
			else if property.value.type() == .text {
				TextField("", text: self.$property.value.valueText)
					.disableAutocorrection(true)
					.multilineTextAlignment(.trailing)
					.autocapitalization(.none)
					.font(.body)
			}
			else if property.value.type() == .number {
				TextField("", text: self.$property.value.valueText)
					.disableAutocorrection(true)
					.multilineTextAlignment(.trailing)
					.autocapitalization(.none)
					.font(.body)
			}
			else {
				Text("Unknown property type.")
			}
		}
    }
}
