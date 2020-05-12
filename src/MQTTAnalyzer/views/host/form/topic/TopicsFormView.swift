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
	@State var lastCreated: TopicSubscriptionFormModel?
	
	var body: some View {
		return Section(header: Text("Subscribe to")) {
			List {
				ForEach(host.subscriptions) { subscription in
					TopicCell(subscription: subscription,
							  deletionHandler: self.deleteSubscription,
							  active: self.lastCreated === subscription)
				}
				.onDelete(perform: self.delete)
				
				Button(action: addSubscription) {
					Text("Add subscription")
				}.font(.body)
			}
		}
	}
	
	func deleteSubscription(subscription: TopicSubscriptionFormModel) {
		host.subscriptions = host.subscriptions.filter { $0.id != subscription.id}
	}
	
	func delete(at offsets: IndexSet) {
		lastCreated = nil
		host.subscriptions.remove(atOffsets: offsets)
	}
	
	func addSubscription() {
		let model = TopicSubscriptionFormModel(topic: "#", qos: 0)
		lastCreated = model
		host.subscriptions.append(model)
	}
}
