//
//  TopicFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct TopicsFormView: View {
	@Binding var host: HostFormModel
	@Binding var selectedSubscription: TopicSubscriptionFormModel?
	@Binding var isNavigatingToSubscription: Bool

	var body: some View {
		Section(header: Text("Subscribe to")) {
			ForEach(host.subscriptions) { subscription in
				NavigationLink(destination: SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)) {
					SubscriptionLabelView(subscription: subscription)
				}
				.contextMenu {
					Button(role: .destructive) {
						deleteSubscription(subscription: subscription)
					} label: {
						Label("Delete", systemImage: "trash")
					}
				}
			}
			.onDelete(perform: self.delete)

			Button {
				addSubscription()
			} label: {
				Text("Add subscription")
			}
			.font(.body)
			.accessibilityLabel("add-subscription")
		}
	}

	func deleteSubscription(subscription: TopicSubscriptionFormModel) {
		host.subscriptions = host.subscriptions.filter { $0.id != subscription.id }
	}

	func delete(at offsets: IndexSet) {
		host.subscriptions.remove(atOffsets: offsets)
	}

	func addSubscription() {
		let model = TopicSubscriptionFormModel(topic: "", qos: 0)
		host.subscriptions.append(model)
		selectedSubscription = model
		ViewSelection.update(newValue: model.id) { _ in
			isNavigatingToSubscription = true
		}
	}
}

struct SubscriptionLabelView: View {
	@ObservedObject var subscription: TopicSubscriptionFormModel

	var body: some View {
		Text(subscription.topic.isEmpty ? "(empty)" : subscription.topic)
			.font(.body)
			.foregroundColor(.secondary)
	}
}
