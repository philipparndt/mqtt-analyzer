//
//  DiagnosticsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DiagnosticsView: View {
	let hostname: String
	let port: Int
	let ssl: Bool
	let untrustedSSL: Bool
	let connectionError: String?
	@Binding var isPresented: Bool
	@StateObject private var runner: DiagnosticRunner
	@State private var hasStarted = false
	/// When set, quick fixes modify the form model instead of persisting to CoreData
	var formModel: Binding<HostFormModel>?

	init(host: Host, isPresented: Binding<Bool>, connectionError: String? = nil) {
		self.hostname = host.settings.hostname
		self.port = Int(host.settings.port)
		self.ssl = host.settings.ssl
		self.untrustedSSL = host.settings.untrustedSSL
		self.connectionError = connectionError
		self._isPresented = isPresented
		self._runner = StateObject(wrappedValue: DiagnosticRunner(context: DiagnosticContext(host: host)))
		self.formModel = nil
	}

	init(hostname: String, port: Int, ssl: Bool, untrustedSSL: Bool,
		 protocolMethod: HostProtocol = .mqtt,
		 isPresented: Binding<Bool>, formModel: Binding<HostFormModel>? = nil) {
		self.hostname = hostname
		self.port = port
		self.ssl = ssl
		self.untrustedSSL = untrustedSSL
		self.connectionError = nil
		self._isPresented = isPresented
		self.formModel = formModel
		self._runner = StateObject(wrappedValue: DiagnosticRunner(context: DiagnosticContext(
			hostname: hostname,
			port: port,
			tlsEnabled: ssl,
			allowUntrusted: untrustedSSL,
			useWebSocket: protocolMethod == .websocket
		)))
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					// Connection error (if provided)
					if let connectionError {
						connectionErrorSection(connectionError)
					}

					// Header info
					headerSection

					Divider()

					// Status summary
					statusSummary

					// Checks
					checksSection
				}
				.padding()
			}
			.navigationTitle("Connection Diagnostics")
			#if !os(macOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					if runner.isRunning {
						Button("Cancel") {
							runner.cancel()
						}
					} else {
						Button("Re-run") {
							syncContextFromFormModel()
							Task {
								await runner.runAll()
							}
						}
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Close") {
						runner.cancel()
						isPresented = false
					}
				}
			}
			.task {
				if !hasStarted {
					hasStarted = true
					await runner.runAll()
				}
			}
		}
		.frame(minWidth: 400, minHeight: 500)
	}

	/// Sync the runner's context with the current form model values before re-running
	private func syncContextFromFormModel() {
		guard let form = formModel?.wrappedValue else { return }
		runner.updateContext(
			hostname: form.hostname,
			port: Int(form.port) ?? 1883,
			tlsEnabled: form.ssl,
			allowUntrusted: form.untrustedSSL,
			useWebSocket: form.protocolMethod == .websocket
		)
	}

	private func connectionErrorSection(_ error: String) -> some View {
		HStack(spacing: 10) {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundColor(.red)
			Text(error)
				.font(.subheadline)
				.textSelection(.enabled)
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color.red.opacity(0.1))
		.cornerRadius(8)
	}

	private var headerSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Image(systemName: "server.rack")
					.foregroundColor(.secondary)
				Text(hostname)
					.font(.headline)
					.textSelection(.enabled)
			}

			HStack(spacing: 16) {
				Label(String(port), systemImage: "network")
					.font(.subheadline)
					.foregroundColor(.secondary)

				if ssl {
					Label("TLS", systemImage: "shield.lefthalf.filled")
						.font(.subheadline)
						.foregroundColor(.green)
				} else {
					Label("No TLS", systemImage: "shield.slash")
						.font(.subheadline)
						.foregroundColor(.orange)
				}

				if untrustedSSL {
					Label("Untrusted", systemImage: "exclamationmark.shield")
						.font(.subheadline)
						.foregroundColor(.orange)
				}
			}
		}
	}

	private var statusSummary: some View {
		HStack(spacing: 12) {
			DiagnosticStatusIcon(status: runner.overallStatus)
				.scaleEffect(1.2)

			VStack(alignment: .leading, spacing: 2) {
				Text(overallStatusTitle)
					.font(.subheadline)
					.fontWeight(.semibold)

				Text(overallStatusDescription)
					.font(.caption)
					.foregroundColor(.secondary)
			}

			Spacer()

			if runner.isRunning {
				ProgressView()
					.controlSize(.small)
			}
		}
		.padding()
		.modifier(GlassPanelBackground())
	}

	private var overallStatusTitle: String {
		switch runner.overallStatus {
		case .pending:
			return "Ready to diagnose"
		case .running:
			return "Running diagnostics..."
		case .success:
			return "All checks passed"
		case .warning:
			return "Some warnings found"
		case .error:
			return "Issues detected"
		}
	}

	private var overallStatusDescription: String {
		let total = runner.checks.count
		let completed = runner.checks.filter { $0.status.isTerminal }.count

		if runner.isRunning {
			return "Completed \(completed) of \(total) checks"
		}

		let errors = runner.checks.filter { $0.status.isError }.count
		let warnings = runner.checks.filter {
			if case .warning = $0.status { return true }
			return false
		}.count

		if errors > 0 {
			return "\(errors) error\(errors == 1 ? "" : "s"), \(warnings) warning\(warnings == 1 ? "" : "s")"
		} else if warnings > 0 {
			return "\(warnings) warning\(warnings == 1 ? "" : "s")"
		} else if completed == total {
			return "No issues found"
		} else {
			return "\(total) checks available"
		}
	}

	private var checksSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Diagnostic Checks")
				.font(.headline)
				.padding(.top, 8)

			ForEach(runner.checks, id: \.checkId) { check in
				if let baseCheck = check as? BaseDiagnosticCheck {
					DiagnosticPanelView(check: baseCheck, context: runner.context, formModel: formModel)
				}
			}
		}
	}
}
