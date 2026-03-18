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
	@State private var showDiagnostics = false

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

			Button {
				showDiagnostics = true
			} label: {
				HStack {
					Image(systemName: "stethoscope")
					Text("Diagnose")
				}
			}
			.buttonStyle(.borderedProminent)
			.tint(.orange)

			Button {
				host.reconnect()
			} label: {
				Image(systemName: "play.fill")
			}
			.buttonStyle(.borderedProminent)
			.tint(.blue)

			Spacer()
		}
		.padding()
		.sheet(isPresented: $showErrorDetails) {
			ErrorDetailsSheet(host: host, isPresented: $showErrorDetails)
		}
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(host: host, isPresented: $showDiagnostics)
		}
	}
}
