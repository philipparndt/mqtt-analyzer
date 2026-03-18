//
//  CertificateChainCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network
import Security

/// Checks the server certificate chain and trust evaluation
final class CertificateChainCheck: BaseDiagnosticCheck, @unchecked Sendable {
	private var connection: NWConnection?

	init() {
		super.init(
			checkId: "cert_chain",
			title: "Certificate Chain",
			iconName: "checkmark.seal",
			dependencies: ["tls_version"]
		)
	}

	/// Thread-safe state for capturing certificate chain data across callbacks
	final class CaptureState: @unchecked Sendable {
		private let lock = NSLock()
		private var _completed = false
		private var _certificates: [SecCertificate] = []
		private var _trustResult: SecTrustResultType = .invalid
		private var _error: String?

		var completed: Bool {
			lock.lock()
			defer { lock.unlock() }
			return _completed
		}

		var certificates: [SecCertificate] {
			lock.lock()
			defer { lock.unlock() }
			return _certificates
		}

		var trustResult: SecTrustResultType {
			lock.lock()
			defer { lock.unlock() }
			return _trustResult
		}

		var capturedError: String? {
			lock.lock()
			defer { lock.unlock() }
			return _error
		}

		func setCertificates(_ certs: [SecCertificate]) {
			lock.lock()
			defer { lock.unlock() }
			_certificates = certs
		}

		func setTrustResult(_ result: SecTrustResultType) {
			lock.lock()
			defer { lock.unlock() }
			_trustResult = result
		}

		func setError(_ error: String?) {
			lock.lock()
			defer { lock.unlock() }
			_error = error
		}

		func markCompleted() -> Bool {
			lock.lock()
			defer { lock.unlock() }
			if _completed { return false }
			_completed = true
			return true
		}
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let hostname = context.hostname
		let port = context.port

		return await withCheckedContinuation { continuation in
			let host = NWEndpoint.Host(hostname)
			let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

			let state = CaptureState()
			let startTime = start
			let checkSelf = self

			// Configure TLS with client certificate support and certificate capture
			let tlsOptions = DiagnosticTLSHelper.createTLSOptions(context: context)

			// Override verify block to capture certificates and evaluate trust.
			// Always accepts so we can inspect certs — trust result is reported in the check output.
			sec_protocol_options_set_verify_block(
				tlsOptions.securityProtocolOptions,
				{ _, trust, completion in
					if let trustRef = sec_trust_copy_ref(trust).takeRetainedValue() as SecTrust? {
						if let chain = SecTrustCopyCertificateChain(trustRef) as? [SecCertificate] {
							state.setCertificates(chain)
						}

						// Add custom server CA if available
						if let host = context.host,
						   let caCerts = (try? loadServerCACertificates(host: host)) ?? nil,
						   !caCerts.isEmpty {
							SecTrustSetAnchorCertificates(trustRef, caCerts as CFArray)
							SecTrustSetAnchorCertificatesOnly(trustRef, false)
						}

						var error: CFError?
						let trusted = SecTrustEvaluateWithError(trustRef, &error)

						if !trusted, let error = error {
							state.setError((error as Error).localizedDescription)
						}

						var result: SecTrustResultType = .invalid
						SecTrustGetTrustResult(trustRef, &result)
						state.setTrustResult(result)
					}

					// Always accept for diagnostics
					completion(true)
				}, DispatchQueue.global()
			)

			let parameters = NWParameters(tls: tlsOptions)
			let connection = NWConnection(host: host, port: nwPort, using: parameters)
			self.connection = connection

			connection.stateUpdateHandler = { [weak self] connState in
				switch connState {
				case .ready:
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					let result = checkSelf.handleReady(
						state: state, context: context,
						hostname: hostname, port: port, duration: duration
					)
					continuation.resume(returning: result)

				case .failed(let error):
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					let result = checkSelf.handleFailed(
						state: state, context: context, error: error,
						hostname: hostname, port: port, duration: duration
					)
					continuation.resume(returning: result)

				case .cancelled:
					guard state.markCompleted() else { return }
					continuation.resume(returning: .warning(
						summary: "Check cancelled",
						message: "Certificate chain check was cancelled",
						duration: checkSelf.elapsed(since: startTime)
					))

				case .setup, .preparing, .waiting:
					break

				@unknown default:
					break
				}
			}

			connection.start(queue: DispatchQueue(label: "cert-chain-check"))

			// Timeout
			DispatchQueue.global().asyncAfter(deadline: .now() + 15) { [weak self] in
				guard state.markCompleted() else { return }
				connection.cancel()
				self?.connection = nil

				continuation.resume(returning: .error(
					summary: "Check timed out",
					message: "Certificate chain check timed out",
					duration: checkSelf.elapsed(since: startTime)
				))
			}
		}
	}

	override func cancel() {
		connection?.cancel()
		connection = nil
		super.cancel()
	}

	// swiftlint:disable:next function_parameter_count
	private nonisolated func handleReady(
		state: CaptureState, context: DiagnosticContext,
		hostname: String, port: Int, duration: TimeInterval
	) -> DiagnosticResult {
		let certs = state.certificates
		let trustResult = state.trustResult
		context.certificateChain = certs
		context.trustResult = trustResult

		if let serverCert = certs.first {
			let certData = SecCertificateCopyData(serverCert) as Data
			context.serverCertData = certData
			context.serverCertInfo = CertificateLoader.parseCertInfo(from: certData)
		}

		let chainLength = certs.count
		let hasCustomCA = context.host.flatMap { getCertificate($0, type: .serverCA) } != nil
		let items = buildChainItems(certs, trustResult: trustResult, hasCustomCA: hasCustomCA)

		switch trustResult {
		case .unspecified, .proceed:
			return .success(
				summary: "Chain valid (\(chainLength) cert\(chainLength == 1 ? "" : "s"))",
				detailItems: items,
				duration: duration
			)
		case .recoverableTrustFailure:
			let msg = state.capturedError ?? "Certificate trust issue"
			if context.allowUntrusted {
				return .warning(
					summary: "Certificate not trusted (untrusted allowed)",
					message: msg,
					detailItems: items,
					duration: duration
				)
			}
			return DiagnosticResult(
				status: .error(msg),
				summary: "Certificate not trusted",
				detailItems: items,
				duration: duration,
				solutions: trustSolutions(certs: certs),
				continuable: true
			)
		default:
			let msg = state.capturedError ?? "Certificate chain validation failed"
			if context.allowUntrusted {
				return .warning(
					summary: "Certificate not trusted (untrusted allowed)",
					message: msg,
					detailItems: items,
					duration: duration
				)
			}
			return DiagnosticResult(
				status: .error(msg),
				summary: "Certificate not trusted",
				detailItems: items,
				duration: duration,
				solutions: trustSolutions(certs: certs),
				commands: [
					DiagnosticCommand(
						label: "Show Chain",
						command: "openssl s_client -connect \(hostname):\(port) "
							+ "-showcerts < /dev/null 2>&1 | grep -E 's:|i:'"
					)
				],
				continuable: true
			)
		}
	}

	private nonisolated func handleFailed(
		state: CaptureState, context: DiagnosticContext, error: NWError,
		hostname: String, port: Int, duration: TimeInterval
	) -> DiagnosticResult {
		context.certificateChain = state.certificates
		context.trustResult = state.trustResult

		let errorDesc = state.capturedError ?? error.localizedDescription

		return .error(
			summary: "Validation failed",
			message: errorDesc,
			details: "Certificate chain validation failed.\n\n**Error:** \(errorDesc)",
			duration: duration,
			solutions: [
				"Check if the certificate is valid and not expired",
				"Verify the hostname matches the certificate",
				"Add required CA certificates",
				"Enable 'Allow Untrusted' for self-signed certificates"
			],
			commands: [
				DiagnosticCommand(
					label: "Verify Certificate",
					command: "openssl s_client -connect \(hostname):\(port) "
						+ "-verify_return_error < /dev/null"
				)
			]
		)
	}

	private func buildChainItems(
		_ chain: [SecCertificate], trustResult: SecTrustResultType, hasCustomCA: Bool = false
	) -> [DetailItem] {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short

		var items: [DetailItem] = []

		for (index, cert) in chain.enumerated() {
			let role = index == 0 ? "Server" : (index == chain.count - 1 ? "Root" : "Intermediate")
			let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "(Unknown)"

			var certItems: [DetailItem] = []

			let certData = SecCertificateCopyData(cert) as Data
			if let info = CertificateLoader.parseCertInfo(from: certData) {
				if let issuer = info.issuer {
					certItems.append(.field(label: "Issuer", value: issuer))
				}
				if let notBefore = info.notBefore {
					certItems.append(.field(label: "Valid from", value: dateFormatter.string(from: notBefore)))
				}
				if let notAfter = info.notAfter {
					certItems.append(.field(label: "Expires", value: dateFormatter.string(from: notAfter)))
				}

				let validSANs = info.subjectAltNames.filter { san in
					let trimmed = san.trimmingCharacters(in: .whitespacesAndNewlines)
					guard !trimmed.isEmpty, trimmed.count >= 3 else { return false }
					return trimmed.contains(".") || trimmed.contains(":")
				}
				if !validSANs.isEmpty {
					certItems.append(.list(items: validSANs))
				}
			}

			items.append(.section(title: "\(index + 1). \(summary) (\(role))", items: certItems))
		}

		items.append(.field(label: "Trust", value: describeTrustResult(trustResult, hasCustomCA: hasCustomCA)))

		return items
	}

	private func describeTrustResult(_ result: SecTrustResultType, hasCustomCA: Bool = false) -> String {
		switch result {
		case .invalid:
			return "Invalid"
		case .proceed:
			return "Trusted (user approved)"
		case .deny:
			return "Denied (user rejected)"
		case .unspecified:
			return hasCustomCA ? "Trusted (custom Server CA)" : "Trusted (system CA)"
		case .recoverableTrustFailure:
			return "Recoverable failure"
		case .fatalTrustFailure:
			return "Fatal failure"
		case .otherError:
			return "Other error"
		@unknown default:
			return "Unknown (\(result.rawValue))"
		}
	}

	private nonisolated func trustSolutions(
		certs: [SecCertificate]
	) -> [DiagnosticSolution] {
		var solutions: [DiagnosticSolution] = []

		// Check if the server cert meets Apple's requirements
		let serverCertCompliant = isServerCertCompliant(certs.first)

		if serverCertCompliant {
			solutions.append(DiagnosticSolution(
				"Save the broker's CA certificate as Server CA",
				quickFix: .saveServerCA
			))
		} else {
			solutions.append(DiagnosticSolution(
				"The server certificate does not meet Apple's requirements "
				+ "(e.g. validity > 825 days or missing SANs). "
				+ "Adding a Server CA will not help."
			))
		}

		solutions.append(DiagnosticSolution(
			"Enable 'Allow Untrusted Certificates'",
			quickFix: .enableUntrusted
		))

		solutions.append(DiagnosticSolution(
			"The certificate may be self-signed or issued by a private CA"
		))

		return solutions
	}

	/// Check if the server certificate meets Apple's TLS requirements
	private nonisolated func isServerCertCompliant(_ cert: SecCertificate?) -> Bool {
		guard let cert = cert else { return false }
		let certData = SecCertificateCopyData(cert) as Data
		guard let info = CertificateLoader.parseCertInfo(from: certData) else { return false }

		// Apple requires validity <= 825 days (since Sep 2020)
		if let notBefore = info.notBefore, let notAfter = info.notAfter {
			let validityDays = Calendar.current.dateComponents(
				[.day], from: notBefore, to: notAfter
			).day ?? 0
			if validityDays > 825 {
				return false
			}
		}

		// Apple requires SAN extension
		let validSANs = info.subjectAltNames.filter { san in
			let trimmed = san.trimmingCharacters(in: .whitespacesAndNewlines)
			return !trimmed.isEmpty && trimmed.count >= 3
				&& (trimmed.contains(".") || trimmed.contains(":"))
		}
		if validSANs.isEmpty {
			return false
		}

		return true
	}
}
