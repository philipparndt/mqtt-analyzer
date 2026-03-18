//
//  SANCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Checks if the hostname matches the certificate's Subject Alternative Names
final class SANCheck: BaseDiagnosticCheck, @unchecked Sendable {

	init() {
		super.init(
			checkId: "san",
			title: "Hostname Match (SAN)",
			iconName: "person.text.rectangle",
			dependencies: ["cert_chain"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let hostname = context.hostname

		guard let certInfo = context.serverCertInfo else {
			return .error(
				summary: "No certificate",
				message: "Server certificate not available",
				details: "The certificate chain check did not capture a server certificate.",
				duration: elapsed(since: start)
			)
		}

		let duration = elapsed(since: start)

		// Use the existing CertificateValidator
		if CertificateValidator.hostnameMatches(hostname, certInfo: certInfo) {
			var details = "Hostname '\(hostname)' matches the certificate.\n\n"
			details += buildCertDetails(certInfo: certInfo, hostname: hostname)

			return .success(
				summary: "Hostname verified",
				details: details,
				duration: duration
			)
		}

		// Hostname doesn't match - provide detailed error
		var details = "Hostname '\(hostname)' does not match the certificate.\n\n"
		details += buildCertDetails(certInfo: certInfo, hostname: hostname)

		// Build suggestions based on SANs
		var solutions = [
			"Use one of the hostnames listed in the certificate's SANs",
			"Update the certificate to include '\(hostname)' as a SAN",
			"Check for typos in the hostname"
		]

		// If there's a wildcard that might work
		if let cn = certInfo.commonName, cn.hasPrefix("*.") {
			let domain = String(cn.dropFirst(2))
			solutions.insert("For wildcard '*.domain.com', use 'subdomain.\(domain)' instead of '\(hostname)'", at: 0)
		}

		return .error(
			summary: "Hostname mismatch",
			message: "Certificate not valid for '\(hostname)'",
			details: details,
			duration: duration,
			solutions: solutions,
			commands: [
				DiagnosticCommand(
					label: "Show SANs",
					command: "openssl s_client -connect \(hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -text | grep -A1 'Subject Alternative Name'"
				),
				DiagnosticCommand(
					label: "Show Subject",
					command: "openssl s_client -connect \(hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -subject"
				)
			]
		)
	}

	private func buildCertDetails(certInfo: CertInfo, hostname: String) -> String {
		var details = ""

		if let cn = certInfo.commonName {
			let match = CertificateValidator.matchesPattern(hostname.lowercased(), pattern: cn.lowercased())
			details += "Common Name (CN): \(cn) \(match ? "[MATCH]" : "")\n"
		}

		let validSANs = certInfo.subjectAltNames
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { CertificateValidator.isValidDomainOrIP($0) }

		if !validSANs.isEmpty {
			details += "\nSubject Alternative Names:\n"
			for san in validSANs {
				let match = CertificateValidator.matchesPattern(hostname.lowercased(), pattern: san.lowercased())
				details += "  - \(san) \(match ? "[MATCH]" : "")\n"
			}
		} else {
			details += "\nNo Subject Alternative Names found.\n"
		}

		return details
	}
}
