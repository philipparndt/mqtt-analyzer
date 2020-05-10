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

	var body: some View {
		return NavigationLink(destination: SubscriptionDetailsView(subscription: subscription)) {
			Group {
				Text(subscription.topic)
					.font(.body)
					.foregroundColor(.secondary)
			}
		}
	}
}
