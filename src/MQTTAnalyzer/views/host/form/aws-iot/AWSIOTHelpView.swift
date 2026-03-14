//
//  AWSIoTHelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-20.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct AWSIoTHelpView: View {
	@Binding var host: HostFormModel

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .top, spacing: 6) {
				Image(systemName: "info.circle")
					.foregroundColor(.blue)
					.font(.caption)
				Text("AWS IoT Core endpoint detected. Use certificate authentication (mTLS) for secure connections.")
					.font(.caption)
					.foregroundColor(.secondary)
			}

			if host.suggestAWSIOTChanges() {
				Button(action: updateSettings) {
					HStack(spacing: 4) {
						Image(systemName: "wand.and.stars")
						Text("Apply AWS IoT defaults")
					}
					.foregroundColor(.accentColor)
					.font(.subheadline)
				}
				.buttonStyle(.plain)
			}

			Link(destination: URL(string: "https://github.com/philipparndt/mqtt-analyzer/blob/master/Docs/examples/aws/README.md")!) {
				HStack(spacing: 4) {
					Image(systemName: "book")
					Text("AWS IoT Documentation")
				}
				.foregroundColor(.accentColor)
				.font(.subheadline)
			}
		}
	}

	func updateSettings() {
		self.host.updateSettingsForAWSIOT()
	}
}
