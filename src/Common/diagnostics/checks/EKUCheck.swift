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
		let ekuResult = CertificateEKUChecker.checkEKU(certData: certData)

		switch ekuResult {
		case .serverAuthPresent:
			return .success(
				summary: "serverAuth present",
				detailItems: [
					.field(label: "TLS Web Server Authentication", value: "present")
				],
				duration: duration
			)

		case .noEKUExtension:
			return .success(
				summary: "No EKU extension (OK)",
				detailItems: [
					.text("Certificate has no Extended Key Usage extension."),
					.text("Per RFC 5280, a certificate without EKU is valid "
						+ "for all purposes including TLS server authentication.")
				],
				duration: duration
			)

		case .serverAuthMissing:
			return .error(
				summary: "Missing serverAuth",
				message: "EKU present but serverAuth missing",
				detailItems: [
					.text("The certificate has an Extended Key Usage extension "
						+ "but it does not include serverAuth."),
					.text("Apple's TLS stack will reject this certificate.")
				],
				duration: duration,
				solutions: [
					"Regenerate the certificate with serverAuth in EKU",
					"Add 'extendedKeyUsage = serverAuth' to the certificate config",
					"Contact the certificate issuer to fix the certificate"
				],
				commands: ekuCommands(context: context)
			)

		case .parseError:
			return .warning(
				summary: "Could not check EKU",
				message: "Failed to parse certificate extensions",
				duration: duration
			)
		}
	}

	private func ekuCommands(context: DiagnosticContext) -> [DiagnosticCommand] {
		[
			DiagnosticCommand(
				label: "Show EKU",
				command: "openssl s_client -connect \(context.hostname):\(context.port) "
					+ "< /dev/null 2>&1 "
					+ "| openssl x509 -noout -text | grep -A1 'Extended Key Usage'"
			),
			DiagnosticCommand(
				label: "Full Cert Info",
				command: "openssl s_client -connect \(context.hostname):\(context.port) "
					+ "< /dev/null 2>&1 | openssl x509 -noout -text"
			)
		]
	}
}
