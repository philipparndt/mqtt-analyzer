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
				Text("New in 2.11").font(.subheadline)
				Spacer()
			}

			InformationDetailView(
				title: "Broker categories",
				subTitle: "You can now organize your brokers by categories!\n\n" +
					"Assign a category to each broker for better organization. " +
					"View brokers grouped by their categories in the broker list.\n\n" +
					"Open Edit broker / More settings.",
				imageName: "tag",
				color: .secondary
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
