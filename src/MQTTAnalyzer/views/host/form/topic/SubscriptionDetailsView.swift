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
				
				Section(header: Text("")) {
					Button(action: close) {
						HStack(alignment: .center) {
							Spacer()
							Text("Delete")
							Spacer()
						}
						}
						.foregroundColor(.red)
						.font(.body)
				}
			}
		}
		.navigationBarTitle("Update subscription")
	}
	
	func close() {
		deletionHandler(subscription)
	}
}
