//
//  InformationDetailView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct InformationDetailView: View {
	var title: String = "title"
	var subTitle: String = "subTitle"
	var imageName: String = "car"
	let color: Color
	
	var body: some View {
		HStack(alignment: .center) {
			Image(systemName: imageName)
				.font(.largeTitle)
				.foregroundColor(color)
				.padding()
				.accessibility(hidden: true)
				.frame(width: 80, alignment: .center)

			VStack(alignment: .leading) {
				Text(title)
					.font(.headline)
					.foregroundColor(.primary)
					.accessibility(addTraits: .isHeader)

				Text(subTitle)
					.font(.body)
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(.top)
	}
}
