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

	var body: some View {
		return Section(header: Text("Subscribe to")) {
			List {
				ForEach(host.subscriptions) { subscription in
					TopicCell(subscription: subscription)
				}
				.onDelete(perform: self.delete)
				
				Button(action: addSubscription) {
					Text("Add subscription")
				}.font(.body)
			}
		}
	}
	
	func delete(at offsets: IndexSet) {
		host.subscriptions.remove(atOffsets: offsets)
	}
	
	func addSubscription() {
		host.subscriptions.append(TopicSubscriptionFormModel(topic: "#", qos: 0))
	}
}
