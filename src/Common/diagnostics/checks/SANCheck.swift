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
		let items = buildCertItems(certInfo: certInfo, hostname: hostname)

		if CertificateValidator.hostnameMatches(hostname, certInfo: certInfo) {
			return .success(
				summary: "Hostname verified",
				detailItems: [.text("Hostname '\(hostname)' matches the certificate.")] + items,
				duration: duration
			)
		}

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
			detailItems: [.text("Hostname '\(hostname)' does not match the certificate.")] + items,
			duration: duration,
			solutions: solutions,
			commands: [
				DiagnosticCommand(
					label: "Show SANs",
					command: "openssl s_client -connect \(hostname):\(context.port) < /dev/null 2>&1 "
						+ "| openssl x509 -noout -text | grep -A1 'Subject Alternative Name'"
				),
				DiagnosticCommand(
					label: "Show Subject",
					command: "openssl s_client -connect \(hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -subject"
				)
			]
		)
	}

	private func buildCertItems(certInfo: CertInfo, hostname: String) -> [DetailItem] {
		var items: [DetailItem] = []

		if let cn = certInfo.commonName {
			let match = CertificateValidator.matchesPattern(
				hostname.lowercased(), pattern: cn.lowercased()
			)
			items.append(.fieldWithStatus(label: "Common Name", value: cn, ok: match))
		}

		let validSANs = certInfo.subjectAltNames
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { CertificateValidator.isValidDomainOrIP($0) }

		if !validSANs.isEmpty {
			var sanItems: [DetailItem] = []
			for san in validSANs {
				let match = CertificateValidator.matchesPattern(
					hostname.lowercased(), pattern: san.lowercased()
				)
				sanItems.append(.fieldWithStatus(label: san, value: "", ok: match))
			}
			items.append(.section(title: "Subject Alternative Names", items: sanItems))
		} else {
			items.append(.text("No Subject Alternative Names found."))
		}

		return items
	}
}
