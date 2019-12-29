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
}

class PostMessagePropertyValueBoolean: PostMessagePropertyValue {
	override func type() -> PostMessagePropertyType {
		return .boolean
	}
}

class PostMessagePropertyValueText: PostMessagePropertyValue {
}

struct PostMessageProperty: Identifiable {
	let id: String = NSUUID().uuidString
	let name: String
	var value: PostMessagePropertyValue
}

struct PostMessageFormModel {
	var topic: String = "/"
    var message: String = ""
    var qos: Int = 0
	var retain: Bool = false
	var properties: [PostMessageProperty] = []
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

			Section(header: Text("Message")) {
				MessageTextView(text: $message.message)
				.disableAutocorrection(true)
				.autocapitalization(.none)
				.font(.system(.body, design: .monospaced))
				.frame(height: 250)
			}
			
			ForEach(message.properties.indices) { index in
				Section(header: Text(self.message.properties[index].name)) {
					MessageProperyView(property: self.$message.properties[index])
				}
			}
			
			QOSSectionView(qos: $message.qos)

			Text("").frame(height: 250) // Scoll Spacer
        }
    }
}

struct MessageProperyView: View {
	@Binding var property: PostMessageProperty
    
    var body: some View {

		HStack {
			if property.value is PostMessagePropertyValueBoolean {
				Toggle(property.name, isOn: self.$property.value.valueBool)
			}
			else if property.value is PostMessagePropertyValueText {
				TextField("", text: self.$property.value.valueText)
				.disableAutocorrection(true)
				.autocapitalization(.none)
				.font(.body)
			}
			else {
				Text("Unknown property type")
			}
		}
    }
}
