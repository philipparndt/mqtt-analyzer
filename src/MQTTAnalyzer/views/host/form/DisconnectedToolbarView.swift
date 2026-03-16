//
//  DisconnectedToolbarView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DisconnectedToolbarView: View {
	@ObservedObject var host: Host
	@State private var showErrorDetails = false

	var body: some View {
		HStack {
			Spacer()

			Button {
				showErrorDetails = true
			} label: {
				HStack {
					Image(systemName: "info.circle.fill")
					Text("Connection Error")
				}
			}
			.buttonStyle(.borderedProminent)
			.tint(.red)

			Button(action: { host.reconnect() }) {
				Image(systemName: "play.fill")
			}
			.buttonStyle(.borderedProminent)
			.tint(.orange)

			Spacer()
		}
		.padding()
		.sheet(isPresented: $showErrorDetails) {
			ErrorDetailsSheet(host: host, isPresented: $showErrorDetails)
		}
	}
}
