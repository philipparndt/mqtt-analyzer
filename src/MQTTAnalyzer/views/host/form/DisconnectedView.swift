//
//  DisconnectedView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DisconnectedView: View {
	@ObservedObject var host: Host
	@State private var showErrorDetails = false
	@State private var showDiagnostics = false

	var body: some View {
		VStack(spacing: 12) {
			HStack(spacing: 12) {
				VStack(alignment: .leading, spacing: 6) {
					Text(host.connectionMessage ?? "Disconnected")
						.lineLimit(2)
						.font(.body)
						.fontWeight(.semibold)

					HStack(spacing: 8) {
						Button {
							showErrorDetails = true
						} label: {
							HStack(spacing: 4) {
								Image(systemName: "info.circle.fill")
								Text("Details")
							}
							.font(.caption)
							.padding(.vertical, 4)
							.padding(.horizontal, 8)
							.background(Color.blue)
							.foregroundColor(.white)
							.cornerRadius(4)
						}

						Button {
							showDiagnostics = true
						} label: {
							HStack(spacing: 4) {
								Image(systemName: "stethoscope")
								Text("Diagnose")
							}
							.font(.caption)
							.padding(.vertical, 4)
							.padding(.horizontal, 8)
							.background(Color.orange)
							.foregroundColor(.white)
							.cornerRadius(4)
						}
					}
				}

				Spacer()

				Button(action: reconnect) {
					HStack {
						Image(systemName: "play.fill")
						Text("Reconnect")
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(4)
				}
			}
		}
		.padding(12)
		.background(Color.red.opacity(0.15))
		.cornerRadius(6)
		.padding(8)
		.sheet(isPresented: $showErrorDetails) {
			ErrorDetailsSheet(host: host, isPresented: $showErrorDetails)
		}
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(host: host, isPresented: $showDiagnostics)
		}
    }

	func reconnect() {
		host.reconnect()
	}
}

struct ErrorDetailsSheet: View {
	var host: Host
	@Binding var isPresented: Bool
	@State private var showDiagnostics = false

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				Text("Connection Error")
					.font(.headline)

				Spacer()

				Button {
					showDiagnostics = true
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "stethoscope")
						Text("Run Diagnostics")
					}
					.font(.subheadline)
				}
				.buttonStyle(.borderedProminent)
				.tint(.orange)

				Button {
					isPresented = false
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(.gray)
				}
				.buttonStyle(.plain)
			}

			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					// Configuration
					Group {
						Text("Configuration")
							.font(.headline)
						VStack(alignment: .leading, spacing: 8) {
							HStack {
								Text("Hostname:")
									.fontWeight(.semibold)
								Text(host.settings.hostname)
									.monospaced()
							}
							HStack {
								Text("Port:")
									.fontWeight(.semibold)
								Text("\(host.settings.port)")
									.monospaced()
							}
							HStack {
								Text("SSL/TLS:")
									.fontWeight(.semibold)
								Text(host.settings.ssl ? "Enabled" : "Disabled")
									.monospaced()
							}
						}
						.padding(8)
						.background(Color.blue.opacity(0.05))
						.cornerRadius(4)
					}

					// Actual Error
					if let summary = host.connectionMessage {
						Group {
							Text("Error Message")
								.font(.headline)
							Text(summary)
								.font(.body)
								.textSelection(.enabled)
								.padding(8)
								.background(Color.red.opacity(0.05))
								.cornerRadius(4)
						}
					}

					// Details
					if let details = host.connectionErrorDetails {
						Group {
							Text("Diagnosis & Solutions")
								.font(.headline)
							Text(details)
								.font(.system(.body, design: .monospaced))
								.textSelection(.enabled)
								.padding(8)
								.background(Color.gray.opacity(0.1))
								.cornerRadius(4)
						}
					}

				}
			}

			Spacer()
		}
		.padding()
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(host: host, isPresented: $showDiagnostics)
		}
	}
}
