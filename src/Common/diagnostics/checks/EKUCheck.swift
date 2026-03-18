//
//  EKUCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Checks if the certificate has the serverAuth Extended Key Usage
final class EKUCheck: BaseDiagnosticCheck, @unchecked Sendable {

	init() {
		super.init(
			checkId: "eku",
			title: "Extended Key Usage",
			iconName: "key.viewfinder",
			dependencies: ["cert_chain"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()

		guard let certData = context.serverCertData else {
			return .error(
				summary: "No certificate",
				message: "Server certificate not available",
				details: "The certificate chain check did not capture a server certificate.",
				duration: elapsed(since: start)
			)
		}

		let duration = elapsed(since: start)

		// Use the existing CertificateEKUChecker
		let hasServerAuth = CertificateEKUChecker.checkServerAuthExtension(certData: certData)

		if hasServerAuth {
			return .success(
				summary: "serverAuth present",
				details: "Certificate includes 'TLS Web Server Authentication' (serverAuth) in Extended Key Usage.\n\nThis is required for server certificates.",
				duration: duration
			)
		}

		// Missing serverAuth
		var details = "Certificate is missing 'TLS Web Server Authentication' (serverAuth) in Extended Key Usage.\n\n"
		details += "This is a required extension for TLS server certificates. Without it, many TLS clients will reject the certificate.\n\n"
		details += "The Extended Key Usage (EKU) extension specifies what purposes a certificate can be used for."

		return .error(
			summary: "Missing serverAuth",
			message: "Certificate lacks serverAuth EKU",
			details: details,
			duration: duration,
			solutions: [
				"Regenerate the certificate with proper Extended Key Usage",
				"Add 'extendedKeyUsage = serverAuth' to the certificate config",
				"Contact the certificate issuer to fix the certificate",
				"For self-signed certificates, regenerate with proper EKU"
			],
			commands: [
				DiagnosticCommand(
					label: "Show EKU",
					command: "openssl s_client -connect \(context.hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -text | grep -A1 'Extended Key Usage'"
				),
				DiagnosticCommand(
					label: "Full Cert Info",
					command: "openssl s_client -connect \(context.hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -text"
				)
			]
		)
	}
}
