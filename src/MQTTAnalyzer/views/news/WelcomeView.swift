//
//  Welcome.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
	let closeHandler: () -> Void

	var body: some View {
		ScrollView {
			TitleView()
				.padding([.top, .bottom], 50)

			InformationContainerView()
				.padding([.bottom], 50)

			Button(action: closeHandler) {
				Text("Start")
			}
			.padding([.bottom], 20)
		}
    }
}
