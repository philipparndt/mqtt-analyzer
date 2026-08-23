//
//  ReadView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// Deliberately not animated: one of these is drawn per row, arriving messages
/// flip the read state constantly, and an animating row keeps the whole list
/// inside an AppKit animation group, re-laying it out on every frame.
struct ReadMarkerView: View {
	var read: Readstate

	var body: some View {
		Image(systemName: "circle.fill")
		.font(.subheadline)
		.foregroundColor(.blue)
		.opacity(read.read ? 0 : 1)
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
	}
}
