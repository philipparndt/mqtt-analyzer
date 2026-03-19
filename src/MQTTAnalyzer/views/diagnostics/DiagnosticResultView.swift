//
//  DiagnosticResultView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI
import CryptoKit

struct DiagnosticResultView: View {
	let result: DiagnosticResult
	let context: DiagnosticContext
	/// When set, quick fixes modify the form model instead of persisting to CoreData
	var formModel: Binding<HostFormModel>?
	@State private var copiedCommand: String?
	@State private var appliedFix: DiagnosticQuickFix?
	@State private var showTrustCertSheet = false
	@State private var showUntrustedAlert = false

	@Environment(\.managedObjectContext) private var viewContext

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Details section
			if !result.detailItems.isEmpty {
				VStack(alignment: .leading, spacing: 4) {
					Text("Details")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					DetailItemsView(items: result.detailItems)
				}
			} else if let details = result.details {
				VStack(alignment: .leading, spacing: 4) {
					Text("Details")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					Text(markdownToAttributedString(details))
						.font(.callout)
						.textSelection(.enabled)
						.fixedSize(horizontal: false, vertical: true)
				}
			}

			// Duration
			if result.duration > 0 {
				HStack {
					Image(systemName: "clock")
						.font(.caption)
						.foregroundColor(.secondary)
					Text(formatDuration(result.duration))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}

			// Solutions section
			if !result.solutions.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					Text("Solutions")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					VStack(alignment: .leading, spacing: 6) {
						ForEach(Array(result.solutions.enumerated()), id: \.offset) { index, solution in
							SolutionRowView(
								index: index,
								solution: solution,
								appliedFix: $appliedFix,
								applyFix: requestQuickFix
							)
						}
					}
				}
				.padding(.top, 4)
			}

			// Commands section
			if !result.commands.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					Text("Useful Commands")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					ForEach(result.commands, id: \.command) { cmd in
						CommandView(command: cmd, copiedCommand: $copiedCommand)
					}
				}
				.padding(.top, 4)
			}
		}
		.sheet(isPresented: $showTrustCertSheet) {
			TrustConfirmationView(
				context: context,
				onConfirm: {
					showTrustCertSheet = false
					applyServerCA()
				},
				onCancel: {
					showTrustCertSheet = false
				}
			)
		}
		.alert("Disable Certificate Validation?", isPresented: $showUntrustedAlert) {
			Button("Allow Untrusted", role: .destructive) {
				applyEnableUntrusted()
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("All certificate validation will be disabled for this broker. "
				+ "The connection will not be protected against man-in-the-middle attacks.")
		}
	}

	private func requestQuickFix(_ fix: DiagnosticQuickFix) {
		switch fix {
		case .saveServerCA:
			showTrustCertSheet = true
		case .enableUntrusted:
			showUntrustedAlert = true
		case .enableTLS, .changePort, .changeHostname, .changeProtocolMethod:
			// Apply immediately — no confirmation needed for non-security changes
			applySimpleFix(fix)
		}
	}

	private func applySimpleFix(_ fix: DiagnosticQuickFix) {
		if var form = formModel?.wrappedValue {
			applySimpleFixToForm(fix, form: &form)
			formModel?.wrappedValue = form
			appliedFix = fix
			return
		}

		guard let host = context.host else { return }

		switch fix {
		case .enableTLS:
			host.settings.ssl = true
			if host.settings.port == 1883 {
				host.settings.port = 8883
			}
		case .changePort(let port):
			host.settings.port = Int32(port)
		case .changeHostname(let hostname):
			host.settings.hostname = hostname
		case .changeProtocolMethod(let method):
			host.settings.protocolMethod = method
		default:
			return
		}

		saveContext()
		appliedFix = fix
	}

	private func applySimpleFixToForm(_ fix: DiagnosticQuickFix, form: inout HostFormModel) {
		switch fix {
		case .enableTLS:
			form.ssl = true
			if form.port == "1883" {
				form.port = "8883"
			}
		case .changePort(let port):
			form.port = "\(port)"
		case .changeHostname(let hostname):
			form.hostname = hostname
		case .changeProtocolMethod(let method):
			form.protocolMethod = method
		default:
			break
		}
	}

	private func applyEnableUntrusted() {
		if formModel != nil {
			formModel?.wrappedValue.untrustedSSL = true
			appliedFix = .enableUntrusted
			return
		}

		guard let host = context.host else { return }
		host.settings.untrustedSSL = true
		saveContext()
		appliedFix = .enableUntrusted
	}

	private func applyServerCA() {
		if formModel != nil {
			applyServerCAToForm()
			appliedFix = .saveServerCA
			return
		}

		guard let host = context.host else { return }
		saveServerCACertificate(host: host)
		host.settings.untrustedSSL = false
		saveContext()
		appliedFix = .saveServerCA
	}

	private func applyServerCAToForm() {
		guard !context.certificateChain.isEmpty else { return }

		// Build PEM with the full certificate chain
		var pemString = ""
		for cert in context.certificateChain {
			let derData = SecCertificateCopyData(cert) as Data
			let base64 = derData.base64EncodedString(options: .lineLength76Characters)
			pemString += "-----BEGIN CERTIFICATE-----\n"
			pemString += base64
			pemString += "\n-----END CERTIFICATE-----\n"
		}

		guard let pemData = pemString.data(using: .utf8) else { return }

		let safeHostname = context.hostname
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: ":", with: "_")
		let fileName = "server-ca-\(safeHostname).pem"

		do {
			let tempDir = FileManager.default.temporaryDirectory
			let tempFile = tempDir.appendingPathComponent(fileName)
			try pemData.write(to: tempFile)

			let hash = computeFileHash(url: tempFile)

			guard let localURL = CloudDataManager.instance.getLocalDocumentDiretoryURL() else { return }
			let targetURL = localURL.appendingPathComponent(fileName)

			if FileManager.default.fileExists(atPath: targetURL.path) {
				try FileManager.default.removeItem(at: targetURL)
			}
			try FileManager.default.copyItem(at: tempFile, to: targetURL)
			try? FileManager.default.removeItem(at: tempFile)

			var certFile = CertificateFile(name: fileName, location: .local, type: .serverCA)
			certFile.fileHash = hash

			formModel?.wrappedValue.certServerCA = certFile
			formModel?.wrappedValue.untrustedSSL = false
		} catch {
			NSLog("Failed to save Server CA: \(error)")
		}
	}

	private func saveServerCACertificate(host: Host) {
		guard !context.certificateChain.isEmpty else { return }

		// Build PEM with the full certificate chain
		var pemString = ""
		for cert in context.certificateChain {
			let derData = SecCertificateCopyData(cert) as Data
			let base64 = derData.base64EncodedString(options: .lineLength76Characters)
			pemString += "-----BEGIN CERTIFICATE-----\n"
			pemString += base64
			pemString += "\n-----END CERTIFICATE-----\n"
		}

		guard let pemData = pemString.data(using: .utf8) else { return }

		// Sanitize hostname for filename
		let safeHostname = context.hostname
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: ":", with: "_")
		let fileName = "server-ca-\(safeHostname).pem"

		do {
			// Write to a temporary file first, then copy via CloudDataManager
			let tempDir = FileManager.default.temporaryDirectory
			let tempFile = tempDir.appendingPathComponent(fileName)
			try pemData.write(to: tempFile)

			let hash = computeFileHash(url: tempFile)

			// Server CA always uses local storage for reliability
			guard let localURL = CloudDataManager.instance.getLocalDocumentDiretoryURL() else {
				return
			}

			let targetURL = localURL.appendingPathComponent(fileName)

			// Remove existing file if present
			if FileManager.default.fileExists(atPath: targetURL.path) {
				try FileManager.default.removeItem(at: targetURL)
			}
			try FileManager.default.copyItem(at: tempFile, to: targetURL)

			// Clean up temp file
			try? FileManager.default.removeItem(at: tempFile)

			// Create certificate file reference
			var certFile = CertificateFile(
				name: fileName,
				location: .local,
				type: .serverCA
			)
			certFile.fileHash = hash

			// Update the broker's certificates
			var certs = host.certificates
			certs.removeAll { $0.type == .serverCA }
			certs.append(certFile)
			host.settings.certificates = Certificates(certs)
		} catch {
			NSLog("Failed to save Server CA: \(error)")
		}
	}

	private func saveContext() {
		do {
			try viewContext.save()
		} catch {
			NSLog("Failed to save: \(error)")
		}
	}

	private func markdownToAttributedString(_ markdown: String) -> AttributedString {
		guard var styled = try? AttributedString(
			markdown: markdown,
			options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
		) else {
			return AttributedString(markdown)
		}

		for run in styled.runs where run.inlinePresentationIntent?.contains(.code) == true {
			styled[run.range].font = .system(.caption, design: .monospaced)
		}

		return styled
	}

	private func formatDuration(_ duration: TimeInterval) -> String {
		if duration < 1 {
			return String(format: "%.0f ms", duration * 1000)
		} else {
			return String(format: "%.2f s", duration)
		}
	}
}

// MARK: - Solution Row

struct SolutionRowView: View {
	let index: Int
	let solution: DiagnosticSolution
	@Binding var appliedFix: DiagnosticQuickFix?
	let applyFix: (DiagnosticQuickFix) -> Void

	private var isApplied: Bool {
		if let applied = appliedFix, let quickFix = solution.quickFix {
			return applied == quickFix
		}
		return false
	}

	var body: some View {
		HStack(alignment: .center, spacing: 8) {
			Text("\(index + 1).")
				.font(.callout)
				.fontWeight(.medium)
				.foregroundColor(.secondary)
				.frame(width: 20, alignment: .leading)

			Text(solution.text)
				.font(.callout)
				.fixedSize(horizontal: false, vertical: true)

			if let quickFix = solution.quickFix {
				Spacer()

				if isApplied {
					Label("Applied", systemImage: "checkmark.circle.fill")
						.font(.caption)
						.foregroundColor(.green)
				} else {
					Button {
						applyFix(quickFix)
					} label: {
						Label("Apply", systemImage: "wand.and.stars")
							.font(.caption)
					}
					.buttonStyle(.bordered)
					.controlSize(.small)
					.tint(.accentColor)
				}
			}
		}
	}
}

// MARK: - Structured Detail Views

struct DetailItemsView: View {
	let items: [DetailItem]

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			ForEach(Array(items.enumerated()), id: \.offset) { _, item in
				DetailItemView(item: item)
			}
		}
	}
}

struct DetailItemView: View {
	let item: DetailItem

	var body: some View {
		switch item {
		case .text(let text):
			Text(text)
				.font(.callout)
				.foregroundColor(.secondary)
				.fixedSize(horizontal: false, vertical: true)

		case .field(let label, let value):
			HStack(alignment: .firstTextBaseline, spacing: 4) {
				Text(label + ":")
					.font(.callout)
					.foregroundColor(.secondary)
				Text(value)
					.font(.callout)
					.textSelection(.enabled)
			}

		case .fieldWithStatus(let label, let value, let ok):
			HStack(alignment: .firstTextBaseline, spacing: 4) {
				Text(label + (value.isEmpty ? "" : ":"))
					.font(.callout)
					.foregroundColor(.secondary)
				if !value.isEmpty {
					Text(value)
						.font(.callout)
						.textSelection(.enabled)
				}
				Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
					.font(.caption)
					.foregroundColor(ok ? .green : .red)
			}

		case .code(let text):
			Text(text)
				.font(.system(.caption, design: .monospaced))
				.textSelection(.enabled)
				.padding(8)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color.primary.opacity(0.05))
				.cornerRadius(6)

		case .section(let title, let items):
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.callout)
					.fontWeight(.semibold)
				DetailItemsView(items: items)
					.padding(.leading, 8)
			}
			.padding(.top, 2)

		case .list(let items):
			VStack(alignment: .leading, spacing: 2) {
				ForEach(items, id: \.self) { item in
					HStack(alignment: .firstTextBaseline, spacing: 6) {
						Text("·")
							.foregroundColor(.secondary)
						Text(item)
							.font(.callout)
							.textSelection(.enabled)
					}
				}
			}
		}
	}
}

// MARK: - Command View

struct CommandView: View {
	let command: DiagnosticCommand
	@Binding var copiedCommand: String?

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(command.label)
				.font(.caption)
				.foregroundColor(.secondary)

			HStack {
				Text(command.command)
					.font(.system(.caption, design: .monospaced))
					.textSelection(.enabled)
					.padding(8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.primary.opacity(0.05))
					.cornerRadius(6)

				Button {
					Pasteboard.copy(command.command)
					copiedCommand = command.command
					DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
						if copiedCommand == command.command {
							copiedCommand = nil
						}
					}
				} label: {
					Image(systemName: copiedCommand == command.command ? "checkmark" : "doc.on.doc")
						.font(.caption)
						.foregroundColor(copiedCommand == command.command ? .green : .secondary)
				}
				.buttonStyle(.plain)
				.help("Copy to clipboard")
			}
		}
	}
}

// MARK: - Trust Confirmation

struct TrustConfirmationView: View {
	let context: DiagnosticContext
	let onConfirm: () -> Void
	let onCancel: () -> Void

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					HStack {
						Spacer()
						Image(systemName: "shield.lefthalf.filled.trianglebadge.exclamationmark")
							.font(.system(size: 48))
							.foregroundColor(.orange)
						Spacer()
					}
					.padding(.top, 8)

					Text("Trust this server's certificate?")
						.font(.headline)
						.frame(maxWidth: .infinity, alignment: .center)

					Text("The server's certificate chain will be saved as a trusted CA. "
						+ "Only do this if you trust this server and have verified the fingerprint.")
						.font(.callout)
						.foregroundColor(.secondary)

					// Server & certificate info
					VStack(alignment: .leading, spacing: 8) {
						DetailItemView(item: .field(
							label: "Server",
							value: "\(context.hostname):\(context.port)"
						))

						if let cert = context.certificateChain.first {
							let fingerprint = certificateFingerprint(cert)
							VStack(alignment: .leading, spacing: 4) {
								Text("Fingerprint (SHA-256):")
									.font(.caption)
									.foregroundColor(.secondary)
								Text(fingerprint)
									.font(.system(.caption2, design: .monospaced))
									.textSelection(.enabled)
									.padding(8)
									.frame(maxWidth: .infinity, alignment: .leading)
									.background(Color.primary.opacity(0.05))
									.cornerRadius(6)
							}

							if let info = context.serverCertInfo {
								if let cn = info.commonName {
									DetailItemView(item: .field(label: "Subject", value: cn))
								}
								if let issuer = info.issuer {
									DetailItemView(item: .field(label: "Issuer", value: issuer))
								}
							}
						}
					}
					.padding()
					.background(Color.primary.opacity(0.03))
					.cornerRadius(10)

					VStack(spacing: 12) {
						Button(action: onConfirm) {
							Label("Trust and Save Certificate", systemImage: "checkmark.shield")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.borderedProminent)
						.tint(.orange)

						Button(action: onCancel) {
							Text("Cancel")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.bordered)
					}
					.padding(.top, 8)
				}
				.padding()
			}
			.navigationTitle("Trust Server")
			#if !os(macOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
		}
		.frame(minWidth: 380, minHeight: 420)
	}

	private func certificateFingerprint(_ cert: SecCertificate) -> String {
		let data = SecCertificateCopyData(cert) as Data
		let digest = SHA256.hash(data: data)
		let bytes = Array(digest)
		let hexParts = bytes.map { String(format: "%02X", $0) }
		return hexParts
			.enumerated()
			.map { $0.offset > 0 && $0.offset % 8 == 0 ? "\n\($0.element)" : $0.element }
			.joined(separator: ":")
	}
}
