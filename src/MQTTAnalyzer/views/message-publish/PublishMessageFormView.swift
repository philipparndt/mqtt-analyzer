//
//  PublishMessageFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftyJSON
import swift_petitparser

enum PublishMessagePropertyType {
	case boolean
	case number
	case text
}

class PublishMessagePropertyValue {
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
	
	func type() -> PublishMessagePropertyType {
		return .text
	}
	
	func getTypedValue() -> Any {
		return valueText
	}
}

class PublishMessagePropertyValueBoolean: PublishMessagePropertyValue {
	override func type() -> PublishMessagePropertyType {
		return .boolean
	}
	
	override func getTypedValue() -> Any {
		return valueBool
	}
}

class PublishMessagePropertyValueNumber: PublishMessagePropertyValue {
	override func type() -> PublishMessagePropertyType {
		return .number
	}
	
	override func getTypedValue() -> Any {
		return Double(valueText) ?? 0
	}
}

class PublishMessagePropertyValueText: PublishMessagePropertyValue {
}

struct PublishMessageProperty: Identifiable {
	let id: String = NSUUID().uuidString
	let name: String
	let pathName: String
	let path: [JSONSubscriptType]
	var value: PublishMessagePropertyValue
}

struct PublishMessageFormModalView: View {
	let closeCallback: () -> Void
	let root: RootModel
	let host: Host
	@Binding var model: PublishMessageFormModel

	var body: some View {
		NavigationView {
			PublishMessageFormView(message: self.$model, type: self.$model.messageType)
				.font(.caption)
				.navigationBarTitle(Text("Publish message"))
				.navigationBarItems(
					leading: Button(action: self.cancel) {
						Text("Cancel")
						
					}.buttonStyle(ActionStyleT50()),
					trailing: Button(action: self.publish) {
						Text("Publish")
					}.buttonStyle(ActionStyleL50())
			)
			.keyboardResponsive()
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
		
	func publish() {
		if model.messageType == .json {
			model.updateMessageFromJsonData()
		}
		
		let msg = Message(data: model.message,
						  date: Date.init(),
						  qos: Int32(model.qos), retain: model.retain, topic: model.topic)
		
		root.publish(message: msg, on: self.host)
		
		closeCallback()
	}
	
	func cancel() {
		closeCallback()
	}
}

struct PublishMessageFormView: View {
	@Binding var message: PublishMessageFormModel
	@Binding var type: PublishMessageType

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
				PublishMessageTypeView(type: self.$type)
				
				if type == .json {
					PublishMessageFormJSONView(message: $message)
				}
				else {
					PublishMessageFormPlainTextView(message: $message.message)
				}
			}
		}
	}
}
enum PublishMessageType {
	case plain
	case json
}

struct PublishMessageTypeView: View {
	@Binding var type: PublishMessageType

	var body: some View {
		Picker(selection: $type, label: Text("Type")) {
			Text("Plain text").tag(PublishMessageType.plain)
			Text("JSON").tag(PublishMessageType.json)
		}.pickerStyle(SegmentedPickerStyle())
	}
}

struct PublishMessageFormPlainTextView: View {
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

struct PublishMessageFormJSONView: View {
	@Binding var message: PublishMessageFormModel
	
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
	@Binding var property: PublishMessageProperty
	
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
