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
				Text("New in 2.8").font(.subheadline)
				Spacer()
			}

			InformationDetailView(
				title: "Charts",
				subTitle: "Data series are now visualized in a chart view.",
				imageName: "chart.xyaxis.line",
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
