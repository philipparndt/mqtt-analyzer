//
//  MetadataView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MetadataTextView: View {
	let key: String?
	let value: String
	
	var body: some View {
		HStack {
			if key != nil {
				Text(key!)
					.foregroundColor(.secondary)
				Spacer()
			}
			Text(value).padding(.trailing)
				.textSelection(.enabled)
			
			if key == nil {
				Spacer()
			}
		}.font(.subheadline)
	}
}

extension View {
	func hasScrollEnabled(_ value: Bool) -> some View {
		self.onAppear {
			UITableView.appearance().isScrollEnabled = value
		}
	}
}

struct MetadataView: View {
	let message: MsgMessage
	@Environment(\.colorScheme) var colorScheme
	
	var body: some View {
		HStack {
			VStack {
				MetadataTextView(key: nil, value: message.topic.nameQualified)
				
				Divider()
				MetadataTextView(key: "Timestamp", value: message.metadata.localDate)
				
				Divider()
				MetadataTextView(key: "QoS", value: "\(message.metadata.qos)")
				
				Divider()
				MetadataTextView(key: "Retain", value: "\(message.metadata.retain ? "Yes" : "No")")

				// MQTT 5
				if let responseTopic = message.metadata.responseTopic {
					Divider()
					MetadataTextView(key: "Response topic", value: "\(responseTopic)")
				}
				if let contentType = message.payload.contentType {
					Divider()
					MetadataTextView(key: "Content type", value: "\(contentType)")
				}
				if !message.metadata.userProperty.isEmpty {
					ForEach(message.metadata.userProperty.sorted(by: { $0.key < $1.key })) {
						Divider()
						MetadataTextView(key: $0.key, value: $0.value)
					}
				}
			}
			.padding([.leading, .top, .bottom])
			.background(Color.listItemBackground(colorScheme))
			.cornerRadius(10)
		}
		.padding()
		.background(Color.listBackground(colorScheme))
    }
}
