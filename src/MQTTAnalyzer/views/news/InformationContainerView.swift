//
//  InformationContainerView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct InformationContainerView: View {
    var body: some View {
		VStack(alignment: .leading) {
			HStack(alignment: .center) {
				Spacer()
				Text("New in 2.7").font(.subheadline)
				Spacer()
			}

			InformationDetailView(
				title: "Siri Shortcuts",
				subTitle: "Publish and receive messages in the Shortcuts app.",
				imageName: "flowchart",
				color: .secondary
			)

			InformationDetailView(
				title: "MQTT 5",
				subTitle: "Connect to MQTT 5.0 brokers. View message MIME types and properties.",
				imageName: "5.circle",
				color: .secondary
			)

			InformationDetailView(
				title: "Feedback welcome",
				subTitle: "App Store and GitHub stars are good for motivation. Feedback and" +
				" contributions like ideas, documentation, and source code are welcome.",
				imageName: "star",
				color: .yellow
			)
		}
		.padding(.horizontal)
    }
}
