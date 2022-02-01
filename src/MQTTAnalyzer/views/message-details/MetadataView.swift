//
//  MetadataView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
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
			if #available(macCatalyst 15.0, *) {
				Text(value).padding(.trailing)
					.textSelection(.enabled)
			} else {
				Text(value).padding(.trailing)
			}
		}
	}
}

extension View {
	func hasScrollEnabled(_ value: Bool) -> some View {
		self.onAppear {
			UITableView.appearance().isScrollEnabled = value
		}
	}
}

struct MetadataInnerView: View {
	let message: MsgMessage

	var body: some View {
		VStack {
			MetadataTextView(key: "Topic", value: message.topic.nameQualified)
			Divider()
			MetadataTextView(key: "Timestamp", value: message.metadata.localDate)
			Divider()
			MetadataTextView(key: "QoS", value: "\(message.metadata.qos)")
			Divider()
			MetadataTextView(key: "Retain", value: "\(message.metadata.retain ? "Yes" : "No")")
		}
		.padding([.leading, .top, .bottom])
		.cornerRadius(10)
	}
}

struct MetadataView: View {
	let message: MsgMessage

	var body: some View {
		HStack {
			if #available(macCatalyst 15.0, *) {
				MetadataInnerView(message: message)
					.background(.ultraThinMaterial)
			} else {
				MetadataInnerView(message: message)
			}
		}.padding()
    }
}
