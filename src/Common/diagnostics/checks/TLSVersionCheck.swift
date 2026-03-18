//
//  TLSVersionCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Checks the TLS protocol version negotiated with the server
final class TLSVersionCheck: BaseDiagnosticCheck, @unchecked Sendable {
	private var connection: NWConnection?

	init() {
		super.init(
			checkId: "tls_version",
			title: "TLS Version",
			iconName: "lock.shield",
			dependencies: ["port"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let hostname = context.hostname
		let port = context.port

		return await withCheckedContinuation { continuation in
			let host = NWEndpoint.Host(hostname)
			let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

			// Configure TLS with client certificate support
			let tlsOptions = DiagnosticTLSHelper.createTLSOptions(context: context)
			let parameters = NWParameters(tls: tlsOptions)
			let connection = NWConnection(host: host, port: nwPort, using: parameters)
			self.connection = connection

			// Use a class to safely manage completion state across callbacks
			final class CompletionState: @unchecked Sendable {
				private let lock = NSLock()
				private var _completed = false
				private var _negotiatedVersion: String?

				var completed: Bool {
					lock.lock()
					defer { lock.unlock() }
					return _completed
				}

				var negotiatedVersion: String? {
					lock.lock()
					defer { lock.unlock() }
					return _negotiatedVersion
				}

				func setNegotiatedVersion(_ version: String?) {
					lock.lock()
					defer { lock.unlock() }
					_negotiatedVersion = version
				}

				func markCompleted() -> Bool {
					lock.lock()
					defer { lock.unlock() }
					if _completed { return false }
					_completed = true
					return true
				}
			}

			let state = CompletionState()
			let startTime = start
			let checkSelf = self

			connection.stateUpdateHandler = { [weak self] connState in
				switch connState {
				case .ready:
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)

					// Try to get TLS metadata
					if let metadata = connection.metadata(definition: NWProtocolTLS.definition) as? NWProtocolTLS.Metadata {
						state.setNegotiatedVersion(checkSelf.getTLSVersion(from: metadata))
					}

					connection.cancel()
					self?.connection = nil

					let version = state.negotiatedVersion ?? "Unknown"
					context.tlsVersion = version

					// Check if version is acceptable
					if version.contains("1.3") {
						continuation.resume(returning: .success(
							summary: "TLS 1.3",
							details: "Negotiated **TLS 1.3** — modern and secure",
							duration: duration
						))
					} else if version.contains("1.2") {
						continuation.resume(returning: .success(
							summary: "TLS 1.2",
							details: "Negotiated **TLS 1.2** — secure, but consider upgrading to TLS 1.3",
							duration: duration
						))
					} else if version.contains("1.1") || version.contains("1.0") {
						continuation.resume(returning: .warning(
							summary: version,
							message: "Outdated TLS version",
							details: "Server negotiated **\(version)** which is considered *insecure*.",
							duration: duration,
							solutions: [
								"Contact your broker administrator to enable TLS 1.2 or 1.3",
								"Update the broker software"
							]
						))
					} else {
						continuation.resume(returning: .success(
							summary: "TLS Connected",
							details: "TLS handshake successful. Version: **\(version)**",
							duration: duration
						))
					}

				case .failed(let error):
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					let (message, solutions) = checkSelf.describeTLSError(error, hostname: hostname, port: port)
					continuation.resume(returning: .error(
						summary: "TLS handshake failed",
						message: message,
						details: "Failed to establish TLS connection to **\(hostname):\(port)**\n\n**Error:** \(error.localizedDescription)",
						duration: duration,
						solutions: solutions,
						commands: [
							DiagnosticCommand(
								label: "Test TLS",
								command: "openssl s_client -connect \(hostname):\(port) -servername \(hostname)"
							),
							DiagnosticCommand(
								label: "Show Certificate",
								command: "openssl s_client -connect \(hostname):\(port) -showcerts < /dev/null"
							)
						]
					))

				case .cancelled:
					guard state.markCompleted() else { return }
					continuation.resume(returning: .warning(
						summary: "Check cancelled",
						message: "TLS check was cancelled",
						duration: checkSelf.elapsed(since: startTime)
					))

				case .setup, .preparing, .waiting:
					break

				@unknown default:
					break
				}
			}

			connection.start(queue: DispatchQueue(label: "tls-version-check"))

			// Timeout after 15 seconds
			DispatchQueue.global().asyncAfter(deadline: .now() + 15) { [weak self] in
				guard state.markCompleted() else { return }
				connection.cancel()
				self?.connection = nil

				continuation.resume(returning: .error(
					summary: "TLS handshake timed out",
					message: "TLS negotiation took too long",
					details: "The TLS handshake did not complete within 15 seconds.",
					duration: checkSelf.elapsed(since: startTime),
					solutions: [
						"Server may be overloaded",
						"Check network latency",
						"Verify TLS is enabled on the correct port"
					]
				))
			}
		}
	}

	override func cancel() {
		connection?.cancel()
		connection = nil
		super.cancel()
	}

	private func getTLSVersion(from metadata: NWProtocolTLS.Metadata) -> String {
		let secProtocol = sec_protocol_metadata_get_negotiated_tls_protocol_version(metadata.securityProtocolMetadata)

		switch secProtocol {
		case .TLSv10:
			return "TLS 1.0"
		case .TLSv11:
			return "TLS 1.1"
		case .TLSv12:
			return "TLS 1.2"
		case .TLSv13:
			return "TLS 1.3"
		case .DTLSv10:
			return "DTLS 1.0"
		case .DTLSv12:
			return "DTLS 1.2"
		@unknown default:
			return "Unknown (\(secProtocol.rawValue))"
		}
	}

	private func describeTLSError(_ error: NWError, hostname: String, port: Int) -> (String, [String]) {
		switch error {
		case .tls(let status):
			// Common TLS error codes
			switch status {
			case errSSLCertExpired:
				return ("Certificate has expired", [
					"Contact the broker administrator to renew the certificate",
					"Temporarily enable 'Allow Untrusted Certificates' for testing only"
				])
			case errSSLCertNotYetValid:
				return ("Certificate is not yet valid", [
					"Check if your device clock is correct",
					"Certificate may have a future validity date"
				])
			case errSSLBadCert, errSSLXCertChainInvalid:
				return ("Certificate validation failed", [
					"The server certificate is not trusted",
					"Add the CA certificate to your trust store",
					"Enable 'Allow Untrusted Certificates' for self-signed certificates"
				])
			case errSSLHostNameMismatch:
				return ("Certificate hostname mismatch", [
					"The certificate is not valid for '\(hostname)'",
					"Use the hostname that matches the certificate's SAN",
					"Check certificate Subject Alternative Names"
				])
			case errSSLPeerHandshakeFail:
				return ("Server rejected handshake", [
					"Server may require client certificate",
					"TLS version mismatch",
					"Cipher suite incompatibility"
				])
			case errSSLConnectionRefused:
				return ("TLS connection refused", [
					"Server may not support TLS on this port",
					"Try the non-TLS port (usually 1883)"
				])
			default:
				return ("TLS error (code: \(status))", [
					"Check server TLS configuration",
					"Verify certificate is valid"
				])
			}
		default:
			return (error.localizedDescription, [
				"Check network connection",
				"Verify server is running"
			])
		}
	}
}
