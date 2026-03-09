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
		#if os(iOS)
		self.onAppear {
			UITableView.appearance().isScrollEnabled = value
		}
		#else
		self
		#endif
	}
}

struct MetadataView: View {
	let message: MsgMessage
	let host: Host
	@Environment(\.colorScheme) var colorScheme

	/// Find the QoS of the subscription that matches this message's topic
	private func getSubscriptionQoS(for topic: String) -> Int? {
		host.settings.subscriptions?.subscriptions
			.first { TreeUtils.topicMatchesSubscription(topic: topic, subscription: $0.topic) }?
			.qos
	}

	/// Determine if QoS may have been downgraded by subscription level
	private var mayBeDowngraded: Bool {
		guard let subscriptionQoS = getSubscriptionQoS(for: message.topic.nameQualified) else {
			return false
		}
		// Show indicator when:
		// - Received QoS equals subscription QoS (message was potentially capped)
		// - Subscription QoS < 2 (QoS 2 subscriptions can't limit anything)
		return Int(message.metadata.qos) == subscriptionQoS && subscriptionQoS < 2
	}

	var body: some View {
		HStack {
			VStack {
				MetadataTextView(key: nil, value: message.topic.nameQualified)

				Divider()
				MetadataTextView(key: "Timestamp", value: message.metadata.localDate)

				Divider()
				HStack {
					Text("QoS")
						.foregroundColor(.secondary)
					Spacer()
					QoSBadgeView(qos: message.metadata.qos, mayBeDowngraded: mayBeDowngraded)
						.padding(.trailing)
				}.font(.subheadline)

				if mayBeDowngraded {
					HStack {
						Image(systemName: "info.circle")
							.foregroundColor(.secondary)
						Text("QoS may be limited by subscription level")
							.foregroundColor(.secondary)
						Spacer()
					}
					.font(.caption)
					.padding(.top, 2)
				}
				
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
