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

	var body: some View {
		return Group {
			List {
				HStack {
					Text("Topic")
						.font(.headline)

					Spacer()
					TextField("#", text: $subscription.topic)
						.multilineTextAlignment(.trailing)
						.disableAutocorrection(true)
						.autocapitalization(.none)
						.font(.body)
				}

				HStack {
					Text("QoS")
					.font(.headline)

					Spacer()

					QOSPicker(qos: $subscription.qos)
				}
			}
		}
		.navigationBarTitle("Update subscription")
	}
}
