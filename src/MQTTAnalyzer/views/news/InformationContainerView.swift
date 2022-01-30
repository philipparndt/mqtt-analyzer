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
			InformationDetailView(
				title: "Folder and flat view",
				subTitle: "Toggle between folder and flat view. You will have a much more structured view of your broker.",
				imageName: "folder",
				color: .secondary
			)

			InformationDetailView(
				title: "Mac application",
				subTitle: "MQTTAnalyzer is now available in the App Store on your Mac for free and open source.",
				imageName: "desktopcomputer",
				color: .secondary
			)

			InformationDetailView(
				title: "Feedback welcome",
				subTitle: "App Store and GitHub stars are good for motivation. Feedback and contributions like ideas, documentation, source code are welcome.",
				imageName: "star",
				color: .yellow
			)
		}
		.padding(.horizontal)
    }
}
