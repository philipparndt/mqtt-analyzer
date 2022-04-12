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

	@State private var selection: String?

	var body: some View {
		return Section(header: Text("Subscribe to")) {
			List {
				ForEach(host.subscriptions) { subscription in
					NavigationLink(destination: SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription),
						   tag: subscription.id,
						   selection: $selection) {
						Group {
							Text(subscription.topic)
								.font(.body)
								.foregroundColor(.secondary)
						}
					}
					
				}
				.onDelete(perform: self.delete)
				
				Button(action: addSubscription) {
					Text("Add subscription")
				}
				.font(.body)
				.accessibilityLabel("add-subscription")
			}
		}
	}
	
	func deleteSubscription(subscription: TopicSubscriptionFormModel) {
		host.subscriptions = host.subscriptions.filter { $0.id != subscription.id}
	}
	
	func delete(at offsets: IndexSet) {
		host.subscriptions.remove(atOffsets: offsets)
	}
	
	func addSubscription() {
		let model = TopicSubscriptionFormModel(topic: "#", qos: 0)
		host.subscriptions.append(model)
		
		ViewSelection.update(newValue: model.id) { id in
			selection = id
		}
	}
}
