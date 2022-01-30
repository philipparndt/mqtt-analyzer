//
//  ResumeConnectionView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2021-06-14.
//  Copyright © 2021 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct LimitReachedView: View {
	
	let message: String
	
	var body: some View {
		HStack {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundColor(.yellow)

			VStack {
				HStack {
					Text(message)
					Spacer()
				}
				HStack {
					Text("Hint: Reduce the subscription topic.")
						.foregroundColor(.secondary)
						.opacity(0.8)
					Spacer()
				}
			}.font(.subheadline)

			Spacer()
		}
		.padding()
	}
	
}
