//
//  MetadataView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: - Modern Metadata Row

struct MetadataRow: View {
	let icon: String
	let label: String
	let value: String
	var iconColor: Color = .secondary

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 14, weight: .medium))
				.foregroundColor(iconColor)
				.frame(width: 20)

			Text(label)
				.font(.subheadline)
				.foregroundColor(.secondary)

			Spacer()

			Text(value)
				.font(.subheadline)
				.foregroundColor(.primary)
				.textSelection(.enabled)
		}
		.padding(.vertical, 8)
	}
}

// MARK: - Status Badge

struct StatusBadge: View {
	let text: String
	let color: Color
	var icon: String?

	var body: some View {
		HStack(spacing: 4) {
			if let icon = icon {
				Image(systemName: icon)
					.font(.system(size: 10, weight: .semibold))
			}
			Text(text)
				.font(.caption)
				.fontWeight(.semibold)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(color.opacity(0.15))
		.foregroundColor(color)
		.cornerRadius(6)
	}
}

// MARK: - Main Metadata View

struct MetadataView: View {
	let message: MsgMessage
	let host: Host
	@Environment(\.colorScheme) var colorScheme

	private func getSubscriptionQoS(for topic: String) -> Int? {
		host.settings.subscriptions?.subscriptions
			.first { TreeUtils.topicMatchesSubscription(topic: topic, subscription: $0.topic) }?
			.qos
	}

	private var mayBeDowngraded: Bool {
		guard let subscriptionQoS = getSubscriptionQoS(for: message.topic.nameQualified) else {
			return false
		}
		return Int(message.metadata.qos) == subscriptionQoS && subscriptionQoS < 2
	}

	private var qosColor: Color {
		switch message.metadata.qos {
		case 0: return .orange
		case 1: return .blue
		case 2: return .green
		default: return .gray
		}
	}

	private var qosLabel: String {
		switch message.metadata.qos {
		case 0: return "At most once"
		case 1: return "At least once"
		case 2: return "Exactly once"
		default: return "Unknown"
		}
	}

	var body: some View {
		VStack(spacing: 16) {
			// Topic section
			TopicPathView(topic: message.topic.nameQualified)

			// Message info card
			VStack(spacing: 0) {
				// Timestamp
				MetadataRow(
					icon: "clock",
					label: "Received",
					value: message.metadata.localDate,
					iconColor: .blue
				)

				Divider().padding(.leading, 32)

				// QoS row
				HStack(spacing: 12) {
					Image(systemName: "speedometer")
						.font(.system(size: 14, weight: .medium))
						.foregroundColor(qosColor)
						.frame(width: 20)

					Text("QoS")
						.font(.subheadline)
						.foregroundColor(.secondary)

					Spacer()

					HStack(spacing: 8) {
						QoSBadgeView(qos: message.metadata.qos, mayBeDowngraded: mayBeDowngraded)
						Text(qosLabel)
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}
				.padding(.vertical, 8)

				if mayBeDowngraded {
					HStack(spacing: 6) {
						Image(systemName: "info.circle.fill")
							.font(.system(size: 12))
						Text("QoS may be limited by subscription level")
							.font(.caption)
					}
					.foregroundColor(.orange)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.leading, 32)
					.padding(.bottom, 8)
				}

				Divider().padding(.leading, 32)

				// Retain status
				HStack(spacing: 12) {
					Image(systemName: "pin")
						.font(.system(size: 14, weight: .medium))
						.foregroundColor(message.metadata.retain ? .purple : .secondary)
						.frame(width: 20)

					Text("Retained")
						.font(.subheadline)
						.foregroundColor(.secondary)

					Spacer()

					StatusBadge(
						text: message.metadata.retain ? "Yes" : "No",
						color: message.metadata.retain ? .purple : .secondary,
						icon: message.metadata.retain ? "checkmark" : nil
					)
				}
				.padding(.vertical, 8)

				// MQTT 5 properties
				if let responseTopic = message.metadata.responseTopic {
					Divider().padding(.leading, 32)
					MetadataRow(
						icon: "arrowshape.turn.up.left",
						label: "Response topic",
						value: responseTopic,
						iconColor: .teal
					)
				}

				if let contentType = message.payload.contentType {
					Divider().padding(.leading, 32)
					MetadataRow(
						icon: "doc.text",
						label: "Content type",
						value: contentType,
						iconColor: .indigo
					)
				}

				if !message.metadata.userProperty.isEmpty {
					ForEach(message.metadata.userProperty.sorted(by: { $0.key < $1.key })) { prop in
						Divider().padding(.leading, 32)
						MetadataRow(
							icon: "tag",
							label: prop.key,
							value: prop.value,
							iconColor: .secondary
						)
					}
				}
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 4)
			.background(Color.listItemBackground(colorScheme))
			.cornerRadius(12)
		}
		.padding()
		.background(Color.listBackground(colorScheme))
	}
}
