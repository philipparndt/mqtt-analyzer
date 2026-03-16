//
//  BrokerDetailsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-04.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct BrokerDetailsView: View {
	@ObservedObject var host: Host
	@State private var showErrorDetails = false

	var body: some View {
		VStack(spacing: 0) {
			if host.state == .disconnected {
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						Text("Disconnected")
							.font(.subheadline)
							.fontWeight(.semibold)
						if let msg = host.connectionMessage {
							Text(msg)
								.font(.caption)
								.foregroundColor(.secondary)
								.lineLimit(2)
						}
					}
					Spacer()
					Button {
						showErrorDetails = true
					} label: {
						HStack(spacing: 6) {
							Image(systemName: "info.circle.fill")
							Text("Details")
						}
						.font(.caption)
						.padding(8)
						.background(Color.blue)
						.foregroundColor(.white)
						.cornerRadius(6)
					}
				}
				.padding()
				.background(Color.red.opacity(0.1))
			}

			List {
				Section("Connection") {
				LabeledContent("Host", value: host.settings.hostname)
				LabeledContent("Port", value: "\(host.settings.port)")
				LabeledContent("Protocol", value: protocolName)
				LabeledContent("Version", value: versionName)
				if host.settings.ssl {
					LabeledContent("SSL", value: "Enabled")
				}
			}

			if let subscriptions = host.settings.subscriptions?.subscriptions, !subscriptions.isEmpty {
				Section("Subscriptions") {
					ForEach(subscriptions, id: \.topic) { subscription in
						LabeledContent(subscription.topic, value: "QoS \(subscription.qos)")
					}
				}
			}

			if let clientID = host.settings.clientID, !clientID.isEmpty {
				Section("Client") {
					LabeledContent("Client ID", value: clientID)
				}
			}

			}
			.navigationTitle(host.settings.aliasOrHost)
		}
		.sheet(isPresented: $showErrorDetails) {
			ErrorDetailsSheet(host: host, isPresented: $showErrorDetails)
		}
	}

	var protocolName: String {
		switch host.settings.protocolMethod {
		case .mqtt: return "MQTT"
		case .websocket: return "WebSocket"
		}
	}

	var versionName: String {
		switch host.settings.protocolVersion {
		case .mqtt3: return "3.1.1"
		case .mqtt5: return "5.0"
		}
	}
}
