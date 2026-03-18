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

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let hostname = context.hostname
		let port = context.port

		return await withCheckedContinuation { continuation in
			let host = NWEndpoint.Host(hostname)
			let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

			// Use a class to safely manage state across callbacks
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

			let state = CaptureState()
			let startTime = start
			let checkSelf = self

			// Configure TLS with certificate capture
			let tlsOptions = NWProtocolTLS.Options()

			sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)

			// Set up verification to capture certificates
			sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, trust, completion in
				// Capture the certificate chain
				if let trustRef = sec_trust_copy_ref(trust).takeRetainedValue() as SecTrust? {
					if let chain = SecTrustCopyCertificateChain(trustRef) as? [SecCertificate] {
						state.setCertificates(chain)
					}

					// Evaluate trust
					var error: CFError?
					let trusted = SecTrustEvaluateWithError(trustRef, &error)

					if !trusted, let error = error {
						state.setError((error as Error).localizedDescription)
					}

					var result: SecTrustResultType = .invalid
					SecTrustGetTrustResult(trustRef, &result)
					state.setTrustResult(result)
				}

				// If untrusted is allowed, accept anyway
				if context.allowUntrusted {
					completion(true)
				} else {
					// Let the system decide
					let result = state.trustResult
					completion(result == .unspecified || result == .proceed)
				}
			}, DispatchQueue.global())

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

					// Store results in context
					let certs = state.certificates
					let trustResult = state.trustResult
					context.certificateChain = certs
					context.trustResult = trustResult

					// Extract server cert info
					if let serverCert = certs.first {
						if let certData = SecCertificateCopyData(serverCert) as Data? {
							context.serverCertData = certData
							context.serverCertInfo = CertificateLoader.parseCertInfo(from: certData)
						}
					}

					let chainLength = certs.count
					let details = checkSelf.buildChainDetails(certs, trustResult: trustResult)

					switch trustResult {
					case .unspecified, .proceed:
						continuation.resume(returning: .success(
							summary: "Chain valid (\(chainLength) cert\(chainLength == 1 ? "" : "s"))",
							details: details,
							duration: duration
						))

					case .recoverableTrustFailure:
						continuation.resume(returning: .warning(
							summary: "Trust warning",
							message: state.capturedError ?? "Certificate trust issue",
							details: details,
							duration: duration,
							solutions: [
								"The certificate could not be fully verified",
								"Add the CA certificate to your device's trust store",
								"For self-signed certificates, enable 'Allow Untrusted'"
							]
						))

					default:
						continuation.resume(returning: .error(
							summary: "Chain invalid",
							message: state.capturedError ?? "Certificate chain validation failed",
							details: details,
							duration: duration,
							solutions: [
								"The certificate chain is not trusted",
								"Verify the server's certificate is properly configured",
								"Add missing intermediate certificates on the server",
								"Add the CA certificate to your trust store"
							],
							commands: [
								DiagnosticCommand(
									label: "Show Chain",
									command: "openssl s_client -connect \(hostname):\(port) -showcerts < /dev/null 2>&1 | grep -E 's:|i:'"
								)
							]
						))
					}

				case .failed(let error):
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					// Still store what we captured
					context.certificateChain = state.certificates
					context.trustResult = state.trustResult

					let errorDesc = state.capturedError ?? error.localizedDescription

					continuation.resume(returning: .error(
						summary: "Validation failed",
						message: errorDesc,
						details: "Certificate chain validation failed.\n\nError: \(errorDesc)",
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
								command: "openssl s_client -connect \(hostname):\(port) -verify_return_error < /dev/null"
							)
						]
					))

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

	private func buildChainDetails(_ chain: [SecCertificate], trustResult: SecTrustResultType) -> String {
		var details = "Certificate chain (\(chain.count) certificate\(chain.count == 1 ? "" : "s")):\n\n"

		for (index, cert) in chain.enumerated() {
			let prefix = index == 0 ? "Server" : (index == chain.count - 1 ? "Root" : "Intermediate")
			if let summary = SecCertificateCopySubjectSummary(cert) as String? {
				details += "\(index + 1). [\(prefix)] \(summary)\n"
			} else {
				details += "\(index + 1). [\(prefix)] (Unknown)\n"
			}
		}

		details += "\nTrust result: \(describeTrustResult(trustResult))"
		return details
	}

	private func describeTrustResult(_ result: SecTrustResultType) -> String {
		switch result {
		case .invalid:
			return "Invalid"
		case .proceed:
			return "Trusted (user approved)"
		case .deny:
			return "Denied (user rejected)"
		case .unspecified:
			return "Trusted (system default)"
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
}
