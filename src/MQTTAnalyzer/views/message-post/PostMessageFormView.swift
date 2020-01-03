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
import swift_petitparser

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

class PostMessageFormModel: ObservableObject {
	var topic: String = "/"
    var message: String = ""
    var qos: Int = 0
	var retain: Bool = false
	var jsonData: JSON?
	var properties: [PostMessageProperty] = []
	
	@Published var messageType: PostMessageType = .plain
	
	class func of(message: Message) -> PostMessageFormModel {
		let model = PostMessageFormModel()
		model.message = message.data
		model.topic = message.topic
		model.qos = Int(message.qos)
		model.retain = message.retain
		model.messageType = message.isJson() ? .json : .plain
		
		if message.isJson() {
			let json = JSON(parseJSON: message.data)
			model.jsonData = json
			
			PostMessageFormModel.createJsonProperties(json: json, path: [])
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
	
	class func createJsonProperties(json: JSON, path: [String]) -> [PostMessageProperty] {
		var result: [PostMessageProperty] = []
		json.dictionaryValue
		.forEach {
            let child = $0.value
			var nextPath = path
			nextPath += [$0.key]
			result += createJsonProperties(json: child, path: nextPath)
        }
		
		if let property = createProperty(json: json, path: path) {
			result += [property]
		}
		
		return result
	}
	
	class func createProperty(json: JSON, path: [String]) -> PostMessageProperty? {
		if path.isEmpty {
			return nil
		}
		
		let name = path[path.count - 1]
		let pathName = path.joined(separator: ".")
		
		let raw = json.rawString() ?? ""
		let isInt = NumbersParser.int().trim().end().accept(raw)
		
		if let value = json.bool {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path,
									   value: PostMessagePropertyValueBoolean(value: value))
		}
		else if isInt {
			return PostMessageProperty(name: name, pathName: pathName,
									   path: path, value: PostMessagePropertyValueNumber(value: "\(json.intValue)"))
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
	let closeCallback: () -> Void
    let root: RootModel
	@ObservedObject var model: PostMessageFormModel

    var body: some View {
        NavigationView {
			PostMessageFormView(message: self.model, type: self.$model.messageType)
				.font(.caption)
				.navigationBarTitle(Text("Post message"))
				.navigationBarItems(
					leading: Button(action: self.cancel) {
						Text("Cancel")
						
					}.buttonStyle(ActionStyleLeading()),
					trailing: Button(action: self.post) {
						Text("Post")
					}.buttonStyle(ActionStyleTrailing())
			)
			.keyboardResponsive()
        }
    }
    	
    func post() {
		if model.messageType == .json {
			model.updateMessageFromJsonData()
		}
		
		let msg = Message(data: model.message,
						  date: Date.init(),
						  qos: Int32(model.qos), retain: model.retain, topic: model.topic)
		root.post(message: msg)
		
		closeCallback()
    }
    
    func cancel() {
		closeCallback()
    }
}

struct PostMessageFormView: View {
	@ObservedObject var message: PostMessageFormModel
	@Binding var type: PostMessageType

    var body: some View {
		Form {
			Section(header: Text("Topic")) {
				TextField("#", text: $message.topic)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.font(.body)
			}

			Section(header: Text("Settings")) {
				HStack {
					Text("QoS")
					
					QOSPicker(qos: $message.qos)
				}
				
				Toggle(isOn: $message.retain) {
					Text("Retain")
				}
			}
			
			Section(header: Text("Message")) {
				PostMessageTypeView(type: self.$type)
				
				if type == .json {
					PostMessageFormJSONView(message: message)
				}
				else {
					PostMessageFormPlainTextView(message: $message.message)
				}
			}
		}
    }
}
enum PostMessageType {
	case plain
	case json
}

struct PostMessageTypeView: View {
	@Binding var type: PostMessageType

    var body: some View {
		Picker(selection: $type, label: Text("Type")) {
			Text("Plain text").tag(PostMessageType.plain)
			Text("JSON").tag(PostMessageType.json)
		}.pickerStyle(SegmentedPickerStyle())
    }
}

struct PostMessageFormPlainTextView: View {
	@Binding var message: String
    
    var body: some View {
		Group {
			MessageTextView(text: $message)
			.disableAutocorrection(true)
			.autocapitalization(.none)
			.font(.system(.body, design: .monospaced))
			.frame(height: 250)
		}
    }
}

struct PostMessageFormJSONView: View {
	@ObservedObject var message: PostMessageFormModel
    
    var body: some View {
		Group {
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
