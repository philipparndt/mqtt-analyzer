//
//  DiagnosticsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DiagnosticsView: View {
	let host: Host
	@Binding var isPresented: Bool
	@StateObject private var runner: DiagnosticRunner
	@State private var hasStarted = false

	init(host: Host, isPresented: Binding<Bool>) {
		self.host = host
		self._isPresented = isPresented
		self._runner = StateObject(wrappedValue: DiagnosticRunner(context: DiagnosticContext(host: host)))
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
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
					Button("Close") {
						runner.cancel()
						isPresented = false
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					if runner.isRunning {
						Button("Cancel") {
							runner.cancel()
						}
					} else {
						Button("Re-run") {
							Task {
								await runner.runAll()
							}
						}
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

	private var headerSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Image(systemName: "server.rack")
					.foregroundColor(.secondary)
				Text(host.settings.hostname)
					.font(.headline)
					.textSelection(.enabled)
			}

			HStack(spacing: 16) {
				Label("\(host.settings.port)", systemImage: "network")
					.font(.subheadline)
					.foregroundColor(.secondary)

				if host.settings.ssl {
					Label("TLS", systemImage: "lock.fill")
						.font(.subheadline)
						.foregroundColor(.green)
				} else {
					Label("No TLS", systemImage: "lock.open")
						.font(.subheadline)
						.foregroundColor(.orange)
				}

				if host.settings.untrustedSSL {
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
					DiagnosticPanelView(check: baseCheck)
				}
			}
		}
	}
}
