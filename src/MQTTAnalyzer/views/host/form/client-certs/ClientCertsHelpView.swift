//
//  ClientCertsHelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-20.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ClientCertsHelpView: View {
	@Binding var host: HostFormModel

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .top, spacing: 6) {
				Image(systemName: "info.circle")
					.foregroundColor(.blue)
					.font(.caption)
				Text("Client certificate authentication (mTLS) requires TLS to be enabled.")
					.font(.caption)
					.foregroundColor(.secondary)
			}

			if host.suggestClientCertsTLSChanges() {
				Button(action: updateSettings) {
					HStack(spacing: 4) {
						Image(systemName: "wand.and.stars")
						Text("Enable TLS")
					}
					.foregroundColor(.accentColor)
					.font(.subheadline)
				}
				.buttonStyle(.plain)
			}

			Link(destination: URL(string: "https://github.com/philipparndt/mqtt-analyzer/blob/master/Docs/examples/client-certs/README.md")!) {
				HStack(spacing: 4) {
					Image(systemName: "book")
					Text("Client Certificates Documentation")
				}
				.foregroundColor(.accentColor)
				.font(.subheadline)
			}
		}
	}

	func updateSettings() {
		self.host.updateSettingsForClientCertsTLS()
	}
}
