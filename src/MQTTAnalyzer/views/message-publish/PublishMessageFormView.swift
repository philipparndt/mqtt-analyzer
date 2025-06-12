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
	case onoff
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

class PublishMessagePropertyValueOnOff: PublishMessagePropertyValue {
	override func type() -> PublishMessagePropertyType {
		return .onoff
	}
	
	override func getTypedValue() -> Any {
		return valueBool ? "ON" : "OFF"
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
	@ObservedObject var model: PublishMessageFormModel

	var body: some View {
		NavigationView {
			PublishMessageFormView(model: self.model, type: self.$model.messageType)
				.font(.caption)
				.navigationBarTitleDisplayMode(.inline)
				.navigationTitle("Publish message")
				.toolbar {
					ToolbarItemGroup(placement: .navigationBarLeading) {
						Button(action: cancel) {
							Text("Cancel")
						}
					}
					
					ToolbarItemGroup(placement: .navigationBarTrailing) {
						Button(action: publish) {
							Text("Publish")
						}
					}
				}
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
		
	func publish() {
		if model.messageType == .json {
			model.updateMessageFromJsonData()
		}
		
		if let topic = TopicTree().addTopic(topic: model.topic) {
			let payload = MsgPayload(data: Array(model.message.utf8))
			payload.contentType = model.messageType == .plain ? "text/plain" : "application/json"
			
			let metadata = MsgMetadata(qos: Int32(model.qos), retain: model.retain)
			// metadata.userProperty = ["hi": "there", "foo": "bar"]
			
			let msg = MsgMessage(
				topic: topic,
				payload: payload,
				metadata: metadata
			)
			root.publish(message: msg, on: self.host)
		}
		
		closeCallback()
	}
	
	func cancel() {
		closeCallback()
	}
}

struct PublishMessageFormView: View {
	@ObservedObject var model: PublishMessageFormModel
	@Binding var type: PublishMessageType

	var body: some View {
		Form {
			Section(header: Text("Topic")) {
				TextField("", text: $model.topic)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.font(.body)
					.accessibilityLabel("topic")
				TopicSuffixPickerView(suffix: $model.topicSuffix)
			}

			Section(header: Text("Settings")) {
				HStack {
					Text("QoS")
					QOSPicker(qos: $model.qos)
				}
				Toggle(isOn: $model.retain) {
					Text("Retain")
					Text("keep this message")
				}
			}

			Section(header: Text("Message")) {
				PublishMessageTypeView(type: self.$type)
				if type == .json {
					PublishMessageFormJSONView(model: model)
				}
				else {
					PublishMessageFormPlainTextView(message: $model.message)
				}
			}
		}
		.formStyle(.grouped)
	}
}

enum PublishMessageType {
	case plain
	case jsonText
	case json
}

struct PublishMessageTypeView: View {
	@Binding var type: PublishMessageType

	var body: some View {
		Picker(selection: $type, label: Text("Type")) {
			Text("Plain text").tag(PublishMessageType.plain)
			Text("JSON text").tag(PublishMessageType.jsonText)
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
	@ObservedObject var model: PublishMessageFormModel
	var body: some View {
		Group {
			ForEach(model.properties.indices, id: \.self) { index in
				HStack {
					Text(self.model.properties[index].pathName)
					Spacer()
					MessageProperyView(property: self.$model.properties[index])
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
			else if property.value.type() == .onoff {
				Toggle("ON/OFF", isOn: self.$property.value.valueBool)
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
