//
//  PostMessageFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct PostMessageFormModel {
	var topic: String = "/"
    var message: String = ""
    var qos: Int = 0
	var retain: Bool = false
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
			
			Section(header: Text("QoS")) {
				Picker(selection: $message.qos, label: Text("QoS")) {
                    Text("0").tag(0)
                    Text("1").tag(1)
                    Text("2").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
			}
			
			Text("").frame(height: 250) // Scoll Spacer
        }
    }
}
