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
			Text(value).padding(.trailing)
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

struct MetadataView: View {
	let message: Message
	let topic: Topic

	var body: some View {
		VStack {
			MetadataTextView(key: "Topic", value: topic.name)
			Divider()
			MetadataTextView(key: "Timestamp", value: message.localDate)
			Divider()
			MetadataTextView(key: "QoS", value: "\(message.qos)")
		}
		.padding([.leading, .top, .bottom])
		.background(.ultraThinMaterial)
		.cornerRadius(10)
    }
}
