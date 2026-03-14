//
//  ServerFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct PortSuggestion {
	let port: String
	let label: String
}

struct ServerFormView: View {
	@Binding var host: HostFormModel

	var hostnameInvalid: Bool {
		return !host.hostname.isEmpty
			&& HostFormValidator.validateHostname(name: host.hostname) == nil
	}

	var portInvalid: Bool {
		return HostFormValidator.validatePort(port: host.port) == nil
	}

	var suggestedPorts: [PortSuggestion] {
		switch (host.protocolMethod, host.ssl) {
		case (.mqtt, false):
			return [PortSuggestion(port: "1883", label: "MQTT")]
		case (.mqtt, true):
			return [
				PortSuggestion(port: "8883", label: "MQTTS"),
				PortSuggestion(port: "443", label: "SNI/ALPN")
			]
		case (.websocket, false):
			return [
				PortSuggestion(port: "80", label: "HTTP"),
				PortSuggestion(port: "8080", label: "Alt")
			]
		case (.websocket, true):
			return [PortSuggestion(port: "443", label: "HTTPS")]
		default:
			return [PortSuggestion(port: "1883", label: "MQTT")]
		}
	}

	var body: some View {
		return Section(header: Text("Server")) {
			HStack {
				Text("Alias")
					.foregroundColor(.secondary)
					.font(.headline)
				
				Spacer()
				
				TextField("optional", text: $host.alias)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.accessibilityLabel("alias")
					.font(.body)
			}
			HStack {
				FormFieldInvalidMark(invalid: hostnameInvalid)
				
				Text("Hostname")
					.font(.headline)

				Spacer()

				TextField("ip address / name", text: $host.hostname)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					#if !os(macOS)
.textInputAutocapitalization(.never)
#endif
					.accessibilityLabel("hostname")
					.font(.body)
			}
			
			if host.isAWS() {
				AWSIoTHelpView(host: $host)
			}
			
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					FormFieldInvalidMark(invalid: portInvalid)

					Text("Port")
						.font(.headline)

					Spacer()

					TextField("e.g. 1883", text: $host.port)
						.multilineTextAlignment(.trailing)
						.disableAutocorrection(true)
						.accessibilityLabel("port")
						.font(.body)
						#if !os(macOS)
						.keyboardType(.numberPad)
						#endif
				}

				HStack(spacing: 8) {
					Text("Common ports:")
						.font(.caption)
						.foregroundColor(.secondary)

					ForEach(suggestedPorts, id: \.port) { suggestion in
						Button {
							host.port = suggestion.port
						} label: {
							Text(suggestion.port)
								.font(.caption)
								.padding(.horizontal, 8)
								.padding(.vertical, 4)
								.background(host.port == suggestion.port ? Color.accentColor : Color.secondary.opacity(0.2))
								.foregroundColor(host.port == suggestion.port ? .white : .primary)
								.cornerRadius(4)
						}
						.buttonStyle(.plain)
					}
				}
			}
			
			HStack {
				Text("Protocol")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				ProtocolPicker(type: $host.protocolMethod)
			}
			
			HStack {
				Text("Version")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				ProtocolVersionPicker(version: $host.protocolVersion)
			}
			
			if host.protocolMethod == .websocket {
				HStack {
					Text("Basepath")
						.font(.headline)

					Spacer()

					TextField("/", text: $host.basePath)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					#if !os(macOS)
.textInputAutocapitalization(.never)
#endif
					.font(.body)
				}
			}
		}
	}
	
}
