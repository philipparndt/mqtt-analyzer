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
				Text("New in 3.0").font(.subheadline)
				Spacer()
			}

			InformationDetailView(
				title: "Native macOS app",
				subTitle: "MQTTAnalyzer now runs natively on Mac! " +
					"Enjoy a full macOS experience with native UI and performance.",
				imageName: "desktopcomputer",
				color: .blue
			)

			InformationDetailView(
				title: "Topic tree view",
				subTitle: "Navigate your topics hierarchically with the new tree view. " +
					"Expand and collapse topic levels for better organization.",
				imageName: "list.bullet.indent",
				color: .green
			)

			InformationDetailView(
				title: "Enhanced TLS security",
				subTitle: "ALPN support for TLS connections and Server CA certificate validation. " +
					"Use local certificates or sync them across devices via iCloud.",
				imageName: "lock.shield",
				color: .orange
			)

			InformationDetailView(
				title: "Feedback welcome",
				subTitle: "App Store and GitHub stars are good for motivation. Feedback and" +
				" contributions like ideas, documentation, and source code are welcome.",
				imageName: "star.fill",
				color: .yellow
			)
		}
		.padding(.horizontal)
    }
}
