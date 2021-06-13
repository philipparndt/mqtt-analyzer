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
		Image(systemName: "circle.fill")
		.font(.subheadline)
		.foregroundColor(.blue)
		.opacity(read.read ? 0 : 1)
		.animation(.easeInOut, value: read.read)
	}
}
