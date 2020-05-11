//
//  TopicCell.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicCell: View {
	@ObservedObject var subscription: TopicSubscriptionFormModel
	var deletionHandler: (TopicSubscriptionFormModel) -> Void
	@State var active = false
	
	var body: some View {
		return NavigationLink(destination: SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription), isActive: $active) {
			Group {
				Text(subscription.topic)
					.font(.body)
					.foregroundColor(.secondary)
			}
		}
	}
	
	func deleteSubscription(subscription: TopicSubscriptionFormModel) {
		active = false
		deletionHandler(subscription)
	}
}
