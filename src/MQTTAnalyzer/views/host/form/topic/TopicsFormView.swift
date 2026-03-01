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
	@State private var selectedSubscription: TopicSubscriptionFormModel?
	@State private var isNavigating = false

	var body: some View {
		Section(header: Text("Subscribe to")) {
			ForEach(host.subscriptions) { subscription in
				NavigationLink(destination: SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)) {
					SubscriptionLabelView(subscription: subscription)
				}
			}
			.onDelete(perform: self.delete)

			Button(action: addSubscription) {
				Text("Add subscription")
			}
			.font(.body)
			.accessibilityLabel("add-subscription")
			.navigationDestination(isPresented: $isNavigating) {
				if let subscription = selectedSubscription {
					SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)
				}
			}
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
			isNavigating = true
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
