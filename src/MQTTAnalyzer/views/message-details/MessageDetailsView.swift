//
//  MessageView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MetadataTextView: View {
	let key: String
	let value: String
	
	var body: some View {
		HStack {
			Text(key)
				.foregroundColor(.secondary)
			Spacer()
			Text(value)
		}
	}
}

struct MessageDetailsView: View {
	let message: Message
	let topic: Topic
	
	var body: some View {
		VStack {
			VStack {
				List {
					Section(header: Text("Metadata")) {
						MetadataTextView(key: "Topic", value: topic.name)
						MetadataTextView(key: "Timestamp", value: message.localDate)
						MetadataTextView(key: "QoS", value: "\(message.qos)")
					}
					
					Section(header: Text("Message")) {
						if message.isJson() {
							MessageDetailsJsonView(message: JsonFormatString(json: message.prettyJson()))
						}
						else {
							MessageDetailsPlainTextView(message: message)
						}
					}
				}
				
			}
		}
	}
}

#if DEBUG
struct MessageDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		MessageDetailsView(message: Message(
			data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }",
			date: Date(),
			qos: 0,
			retain: false, topic: "some topic"), topic: Topic("some topic"))
	}
}
#endif
