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
		HStack {
			VStack {
				MetadataTextView(key: nil, value: message.topic.nameQualified)
				Divider()
				MetadataTextView(key: "Timestamp", value: message.metadata.localDate)
				Divider()
				MetadataTextView(key: "QoS", value: "\(message.metadata.qos)")
				Divider()
				MetadataTextView(key: "Retain", value: "\(message.metadata.retain ? "Yes" : "No")")
			}
			.padding([.leading, .top, .bottom])
			.background(.ultraThinMaterial)
			.cornerRadius(10)
		}.padding()
    }
}
