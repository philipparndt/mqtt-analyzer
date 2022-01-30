//
//  TitleView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TitleView: View {
	var body: some View {
		VStack {
			Image("About")
				.resizable()
				.frame(width: 50.0, height: 50.0)
				.cornerRadius(10)
				.shadow(radius: 10)
				.accessibility(identifier: "about.logo")

			Text("Welcome to").font(.title)
			Text("MQTTAnalyzer").font(.title)
		}
	}
}
