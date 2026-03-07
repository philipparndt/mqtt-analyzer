//
//  SubscriptionDetailsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct SubscriptionDetailsView: View {
	@ObservedObject var subscription: TopicSubscriptionFormModel
	var deletionHandler: (TopicSubscriptionFormModel) -> Void
	@Environment(\.dismiss) private var dismiss
	@FocusState private var isTopicFocused: Bool

	var body: some View {
		List {
			Section {
				HStack {
					Text("Topic")
						.font(.headline)

					Spacer()

					TextField("e.g. home/#", text: $subscription.topic)
						.multilineTextAlignment(.trailing)
						.disableAutocorrection(true)
						#if !os(macOS)
						.textInputAutocapitalization(.never)
						#endif
						.font(.body)
						.accessibilityLabel("subscription-topic")
						.focused($isTopicFocused)
				}
			} footer: {
				TopicFilterHelpView()
			}

			Section {
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("QoS")
							.font(.headline)

						Spacer()

						QOSPicker(qos: $subscription.qos)
					}

					QoSDescriptionView(qos: subscription.qos)
						.padding(.top, 4)
				}
			} footer: {
				Text("Quality of Service determines message delivery guarantees")
					.font(.caption)
					.foregroundColor(.secondary)
			}

			Section {
				Button(role: .destructive) {
					close()
				} label: {
					HStack {
						Spacer()
						Text("Delete")
						Spacer()
					}
				}
				.font(.body)
			}
		}
		#if !os(macOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
		.navigationTitle("Subscription")
		.onAppear {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				isTopicFocused = true
			}
		}
	}

	func close() {
		dismiss()
		deletionHandler(subscription)
	}
}

// MARK: - Topic Filter Help

struct TopicFilterHelpView: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Wildcards")
				.font(.caption)
				.fontWeight(.semibold)

			VStack(alignment: .leading, spacing: 4) {
				HStack(alignment: .top, spacing: 8) {
					Text("#")
						.font(.system(.caption, design: .monospaced))
						.fontWeight(.bold)
						.frame(width: 24, alignment: .leading)
					Text("Multi-level: matches any number of levels")
						.font(.caption)
				}

				HStack(alignment: .top, spacing: 8) {
					Text("+")
						.font(.system(.caption, design: .monospaced))
						.fontWeight(.bold)
						.frame(width: 24, alignment: .leading)
					Text("Single-level: matches exactly one level")
						.font(.caption)
				}
			}
			.foregroundColor(.secondary)

			Text("Examples")
				.font(.caption)
				.fontWeight(.semibold)
				.padding(.top, 4)

			VStack(alignment: .leading, spacing: 4) {
				topicExample("home/#", description: "All topics under home/")
				topicExample("sensor/+/temp", description: "Temperature from any sensor")
				topicExample("#", description: "All topics (use with caution)")
			}
		}
		.padding(.top, 4)
	}

	private func topicExample(_ topic: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 8) {
			Text(topic)
				.font(.system(.caption, design: .monospaced))
				.frame(minWidth: 100, alignment: .leading)
			Text(description)
				.font(.caption)
				.foregroundColor(.secondary)
		}
	}
}
