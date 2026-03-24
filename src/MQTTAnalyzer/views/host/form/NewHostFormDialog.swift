//
//  NewHostFormModalView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: Create Host
struct NewHostFormModalView: View {
	let closeHandler: () -> Void
	let root: RootModel
	var hosts: HostsModel
	@State var errorMessage: String?

	@Environment(\.managedObjectContext) private var viewContext
	@State var host: HostFormModel
	@State private var showDiagnostics = false
	@State private var saveDiagnosticPhase: SaveDiagnosticPhase = .idle
	@State private var showDiagnosticFailedAlert = false
	@State private var diagnosticTask: Task<Void, Never>?
	@State private var diagnosticRunner: DiagnosticRunner?

	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
	}

	var body: some View {
		NavigationStack {
			if let message = errorMessage {
				Text(message).foregroundColor(.red)
			}

			EditHostFormView(
				onDelete: closeHandler,
				onCancelDiagnostics: cancelDiagnostics,
				host: $host,
				saveDiagnosticPhase: $saveDiagnosticPhase,
				savedDiagnosticRunner: $diagnosticRunner
			)
				.font(.caption)
				#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
				.navigationTitle("New broker")
				.toolbar {
					ToolbarItemGroup(placement: .cancellationAction) {
						Button(action: cancel) {
							Text("Cancel")
						}
						.disabled(saveDiagnosticPhase == .running)
					}
					#if os(macOS)
					ToolbarItemGroup(placement: .automatic) {
						Button {
							showDiagnostics = true
						} label: {
							Label("Test Connection", systemImage: "stethoscope")
						}
						.disabled(disableSave || saveDiagnosticPhase == .running)
						.tint(saveDiagnosticPhase == .failed
							|| saveDiagnosticPhase == .findings
							? .orange : nil)
					}
					#endif
					ToolbarItem(placement: .confirmationAction) {
						if saveDiagnosticPhase == .running {
							Button(action: cancelDiagnostics) {
								HStack(spacing: 6) {
									ProgressView()
										.controlSize(.small)
									Text("Testing…")
								}
								.frame(width: 80)
							}
						} else {
							Button(action: saveWithDiagnostics) {
								Text("Save")
									.frame(width: 80)
							}
							.disabled(disableSave)
						}
					}
				}
		}
		.alert("Connection Diagnostic Failed",
			   isPresented: $showDiagnosticFailedAlert) {
			Button("Save Anyway", role: .destructive) {
				saveNow()
			}
			Button("Cancel", role: .cancel) {
				saveDiagnosticPhase = .findings
			}
		} message: {
			Text("The connection diagnostic reported errors. Do you still want to save this broker?")
		}
		#if os(macOS)
		.frame(minWidth: 600, idealWidth: 650, maxWidth: 650, minHeight: 500, idealHeight: 600)
		.sheet(isPresented: $showDiagnostics) {
			if let runner = diagnosticRunner {
				DiagnosticsView(
					runner: runner,
					isPresented: $showDiagnostics,
					formModel: $host
				)
			} else {
				DiagnosticsView(
					hostname: host.hostname,
					port: Int(host.port) ?? 1883,
					ssl: host.ssl,
					untrustedSSL: host.untrustedSSL,
					protocolMethod: host.protocolMethod,
					isPresented: $showDiagnostics,
					formModel: $host
				)
			}
		}
		#endif
	}

	func saveWithDiagnostics() {
		if !validate(source: host) {
			return
		}

		saveDiagnosticPhase = .running

		let runner = DiagnosticRunner(context: DiagnosticContext(
			hostname: host.hostname,
			port: Int(host.port) ?? 1883,
			tlsEnabled: host.ssl,
			allowUntrusted: host.untrustedSSL,
			useWebSocket: host.protocolMethod == .websocket
		))
		diagnosticRunner = runner

		diagnosticTask = Task {
			await runner.runAll()

			guard !Task.isCancelled else { return }

			let hasErrors = runner.checks.contains { $0.status.isError }

			if hasErrors {
				saveDiagnosticPhase = .failed
				showDiagnosticFailedAlert = true
			} else {
				saveDiagnosticPhase = .success
				try? await Task.sleep(nanoseconds: 500_000_000)
				saveNow()
			}
		}
	}

	func cancelDiagnostics() {
		diagnosticRunner?.cancel()
		diagnosticTask?.cancel()
		diagnosticTask = nil
		diagnosticRunner = nil
		saveDiagnosticPhase = .idle
	}

	func saveNow() {
		do {
			let broker = BrokerSetting(context: viewContext)
			broker.id = UUID()
			try copyBroker(target: broker, source: host)

			try viewContext.save()
			DispatchQueue.main.async {
				self.closeHandler()
			}
		} catch {
			let nsError = error as NSError
			errorMessage = "Unresolved error \(nsError), \(nsError.userInfo)"
		}
	}

	func cancel() {
		closeHandler()
	}
}
