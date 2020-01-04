//
//  ReadView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ReadMarkerView: View {
	@ObservedObject
	var read: Readstate
	
	var body: some View {
		Group {
			if read.read {
				Spacer()
					.fixedSize()
					.frame(width: 23, height: 23)
			}
			else {
				Image(systemName: "circle.fill")
				.font(.subheadline)
				.foregroundColor(.blue)
			}
		}
		.scaleEffect(read.read ? 0 : 1)
		.animation(.easeInOut)
	}
}
