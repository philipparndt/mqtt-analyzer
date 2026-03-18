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
	var body: some View {
		VStack(spacing: 0) {
			if host.state == .disconnected {
				ConnectionStatusBanner(
					message: host.connectionMessage ?? "Disconnected",
					icon: "exclamationmark.triangle.fill",
					color: .orange,
					action: { host.reconnect() },
					host: host
				)
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
