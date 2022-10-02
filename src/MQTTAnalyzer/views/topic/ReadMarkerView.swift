//
//  ReadView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ReadMarkerView: View {
	var read: Readstate
	
	var body: some View {
		Image(systemName: "circle.fill")
		.font(.subheadline)
		.foregroundColor(.blue)
		.opacity(read.read ? 0 : 1)
		.animation(.easeInOut, value: read.read)
	}
}

struct FolderReadMarkerView: View {
	var read: Readstate
	
	var body: some View {
		Image(systemName: read.read ? "folder.fill" : "circle.fill")
		.font(.subheadline)
		.foregroundColor(read.read ? .primary : .blue)
		.opacity(read.read ? 0.5 : 1)
		.frame(width: 25, alignment: .center)
		.animation(Animation.easeInOut(duration: 0.5), value: read.read)
	}
}
