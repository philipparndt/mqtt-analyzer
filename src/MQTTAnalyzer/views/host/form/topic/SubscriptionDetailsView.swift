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

	var body: some View {
		return Group {
			List {
				HStack {
					Text("Topic")
						.font(.headline)

					Spacer()
					TextField("e.g. #", text: $subscription.topic)
						.multilineTextAlignment(.trailing)
						.disableAutocorrection(true)
						#if !os(macOS)
.textInputAutocapitalization(.never)
#endif
						.font(.body)
						.accessibilityLabel("subscription-topic")
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
		#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
		.navigationTitle("Update subscription")
	}

	func close() {
		dismiss()
		deletionHandler(subscription)
	}
}
