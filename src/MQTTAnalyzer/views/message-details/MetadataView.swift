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

	var body: some View {
		CustomList {
			MetadataTextView(key: nil, value: message.topic.nameQualified)
			MetadataTextView(key: "Timestamp", value: message.metadata.localDate)
			MetadataTextView(key: "QoS", value: "\(message.metadata.qos)")
			MetadataTextView(key: "Retain", value: "\(message.metadata.retain ? "Yes" : "No")")

			// MQTT 5
			MetadataTextView(key: "Response topic", value: "\(message.metadata.responseTopic ?? "n.a.")")
			MetadataTextView(key: "Content type", value: "\(message.payload.contentType ?? "n.a.")")
			// MetadataTextView(key: "Properties", value: "\(message.metadata.userProperty.debugDescription)")
		}
    }
}
