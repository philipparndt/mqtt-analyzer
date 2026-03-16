//
//  CertificateDiagnostics.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Security

/// High-level certificate diagnostics for MQTT connections
struct CertificateDiagnostics {
	static func diagnose(hostname: String, host: Host) -> String {
		NSLog("CertificateDiagnostics.diagnose(host:) called for hostname=\(hostname)")
		var caPath: String?

		NSLog("CertificateDiagnostics: Attempting to get server CA certificate")
		do {
			// Get the server CA certificate from host's certificate list
			let certificates = host.certificates
			NSLog("CertificateDiagnostics: Host has \(certificates.count) certificates")

			if let certFile = certificates.first(where: { $0.type == .serverCA }) {
				NSLog("CertificateDiagnostics: Found server CA certFile: \(certFile.name), location=\(certFile.location)")
				let url = try certFile.getFullPath()
				caPath = url.path
				NSLog("CertificateDiagnostics: Resolved path: \(caPath ?? "nil")")
			} else {
				NSLog("CertificateDiagnostics: No server CA certificate found in host settings")
			}
		} catch {
			NSLog("CertificateDiagnostics: Error: \(error)")
		}

		NSLog("CertificateDiagnostics: Calling diagnose with certPath=\(caPath ?? "nil")")
		return diagnose(hostname: hostname, certPath: caPath)
	}

	static func diagnose(hostname: String, certPath: String?) -> String {
		var output = "CERTIFICATE DIAGNOSTICS\n"
		output += String(repeating: "=", count: 50) + "\n\n"

		// Configuration section
		output += "CONFIGURATION:\n"
		output += "• Hostname: \(hostname)\n"
		output += "• SSL: Enabled\n"
		if let path = certPath {
			// Show escaped path for CLI usage
			let escapedPath = path.replacingOccurrences(of: " ", with: "\\ ")
			output += "• CA Certificate: \(escapedPath)\n"
		} else {
			output += "• CA Certificate: NOT PROVIDED\n"
		}
		output += "\n"

		// Certificate details section
		if let path = certPath {
			if let certInfo = CertificateLoader.loadCertInfo(from: path) {
				output += "CERTIFICATE:\n"
				if let cn = certInfo.commonName {
					output += "• Subject: \(cn)\n"
				} else {
					output += "• Subject: (unable to extract)\n"
				}
				// Filter out empty/whitespace-only SANs and validate they look like domain names or IPs
				let validSANs = certInfo.subjectAltNames
					.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
					.filter { CertificateValidator.isValidDomainOrIP($0) }

				if !validSANs.isEmpty {
					output += "• SANs: \(validSANs.joined(separator: ", "))\n"
				} else {
					output += "• SANs: (none found)\n"
				}
				output += "\n"

				// Hostname check
				output += "HOSTNAME CHECK:\n"
				if CertificateValidator.hostnameMatches(hostname, certInfo: certInfo) {
					output += "✓ Hostname matches certificate\n"
				} else {
					output += "✗ Hostname mismatch\n"
					output += "  Configured: \(hostname)\n"
					// Filter and clean SANs for display
					let validSANs = ([certInfo.commonName].compactMap { $0 } + certInfo.subjectAltNames)
						.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
						.filter { CertificateValidator.isValidDomainOrIP($0) }
					if !validSANs.isEmpty {
						output += "  Certificate SANs: \(validSANs.joined(separator: ", "))\n"
					} else {
						output += "  Certificate SANs: (none)\n"
					}
				}
				output += "\n"
			} else {
				output += "CERTIFICATE:\n"
				output += "❌ Could not load certificate from path\n"
				output += "   \(path)\n"
				output += "   Check if file exists, is readable, and is in PEM or DER format.\n"
				output += "\n"
			}
		} else {
			output += "CERTIFICATE:\n"
			output += "⚠️  No certificate file provided\n"
			output += "   Cannot perform certificate diagnostics.\n"
			output += "\n"
		}

		// Try to fetch and analyze the server's actual certificate
		output += "SERVER CERTIFICATE CHECK:\n"
		if let serverCertAnalysis = analyzeServerCertificate(hostname: hostname) {
			output += serverCertAnalysis
		} else {
			output += "⚠️  Could not connect to server to verify certificate details\n"
		}
		output += "\n"

		// Solutions section
		output += "SOLUTIONS:\n"
		output += "1. Verify the server certificate has proper Extended Key Usage\n"
		output += "   Must include: 'Extended Key Usage: TLS Web Server Authentication' (serverAuth)\n"
		output += "2. Check server certificate with:\n"
		output += "   openssl s_client -connect \(hostname):443 -showcerts < /dev/null\n"
		output += "3. Update hostname to match one of the certificate's SANs\n"
		output += "4. Ensure certificate chain is complete and valid\n"
		output += "5. ⚠️  DEVELOPMENT ONLY - 'Allow Untrusted Certificates' disables all validation\n"
		output += "   This is INSECURE and should NEVER be used in production\n"
		output += "   Only use for testing with self-signed certificates during development\n"

		return output
	}

	/// Analyzes the server's actual certificate by attempting a TLS connection
	private static func analyzeServerCertificate(hostname: String) -> String? {
		var result = ""
		let semaphore = DispatchSemaphore(value: 0)

		// Create a custom URLSessionDelegate to capture the server certificate
		class CertificateCapturingDelegate: NSObject, URLSessionDelegate {
			var capturedCertificate: SecCertificate?
			var capturedError: Error?

			func urlSession(
				_ session: URLSession,
				didReceive challenge: URLAuthenticationChallenge,
				completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
			) {
				if let trust = challenge.protectionSpace.serverTrust {
					// Capture the leaf certificate (server's own certificate)
					if let certChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
					   let leafCert = certChain.first {
						self.capturedCertificate = leafCert
					}
				}
				// Reject to avoid actual connection, we just wanted the cert
				completionHandler(.cancelAuthenticationChallenge, nil)
			}
		}

		let delegate = CertificateCapturingDelegate()
		let config = URLSessionConfiguration.default
		config.timeoutIntervalForRequest = 2
		config.timeoutIntervalForResource = 3
		let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

		// Try to connect to the MQTT server using HTTPS (port 443)
		// This will trigger the TLS handshake and capture the certificate
		let urlString = "https://\(hostname):443/"
		if let url = URL(string: urlString) {
			let task = session.dataTask(with: url) { _, _, _ in
				// We don't care about the response, just the certificate capture
				semaphore.signal()
			}
			task.resume()

			// Wait for the connection attempt
			_ = semaphore.wait(timeout: .now() + 4)
			task.cancel()
		}

		session.invalidateAndCancel()

		// Analyze the captured certificate
		if let cert = delegate.capturedCertificate {
			result += "✓ Successfully retrieved server certificate\n"

			// Extract subject
			if let subject = SecCertificateCopySubjectSummary(cert) as String? {
				result += "• Server Subject: \(subject)\n"
			}

			// Extract and analyze Extended Key Usage using DER parser
			if let certData = SecCertificateCopyData(cert) as Data? {
				let hasServerAuth = CertificateLoader.checkServerAuthExtension(certData: certData)
				if hasServerAuth {
					result += "✓ Extended Key Usage includes serverAuth\n"
				} else {
					result += "✗ Extended Key Usage missing serverAuth\n"
					result += "   Server certificate must have 'TLS Web Server Authentication'\n"
				}
			}

			return result
		} else {
			// Could not connect - this might be normal if firewall blocks it
			return "⚠️  Could not connect to server to retrieve certificate\n" +
				   "   This is normal if your device cannot reach the broker\n" +
				   "   Verify server certificate has:\n" +
				   "   • Extended Key Usage: TLS Web Server Authentication (serverAuth)\n" +
				   "   • Subject matches or is in SANs\n"
		}
	}
}
