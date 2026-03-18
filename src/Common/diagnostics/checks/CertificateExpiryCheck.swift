//
//  CertificateExpiryCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Checks certificate expiration dates
final class CertificateExpiryCheck: BaseDiagnosticCheck, @unchecked Sendable {

	init() {
		super.init(
			checkId: "cert_expiry",
			title: "Certificate Expiry",
			iconName: "calendar.badge.clock",
			dependencies: ["cert_chain"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()

		guard let certInfo = context.serverCertInfo else {
			return .error(
				summary: "No certificate",
				message: "Server certificate not available",
				details: "The certificate chain check did not capture a server certificate.",
				duration: elapsed(since: start)
			)
		}

		guard let notAfter = certInfo.notAfter else {
			return .warning(
				summary: "Unknown expiry",
				message: "Could not determine expiration date",
				details: "The certificate's expiration date could not be parsed.",
				duration: elapsed(since: start)
			)
		}

		let now = Date()
		let duration = elapsed(since: start)

		// Check if already expired
		if notAfter < now {
			let expiredAgo = formatTimeInterval(now.timeIntervalSince(notAfter))
			return .error(
				summary: "Expired \(expiredAgo) ago",
				message: "Certificate has expired",
				details: buildDetails(certInfo: certInfo, status: "EXPIRED"),
				duration: duration,
				solutions: [
					"Contact the broker administrator to renew the certificate",
					"The certificate expired on \(formatDate(notAfter))",
					"Temporarily enable 'Allow Untrusted' for testing only"
				],
				commands: [
					DiagnosticCommand(
						label: "Check Expiry",
						command: "openssl s_client -connect \(context.hostname):\(context.port) < /dev/null 2>&1 | openssl x509 -noout -dates"
					)
				]
			)
		}

		// Check if not yet valid
		if let notBefore = certInfo.notBefore, notBefore > now {
			let validIn = formatTimeInterval(notBefore.timeIntervalSince(now))
			return .error(
				summary: "Not yet valid",
				message: "Certificate is not yet valid",
				details: buildDetails(certInfo: certInfo, status: "NOT YET VALID"),
				duration: duration,
				solutions: [
					"Certificate becomes valid on \(formatDate(notBefore))",
					"Check if your device's date and time are correct",
					"The certificate will be valid in \(validIn)"
				]
			)
		}

		// Calculate days until expiry
		let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: notAfter).day ?? 0

		if daysUntilExpiry <= 7 {
			return .error(
				summary: "Expires in \(daysUntilExpiry) day\(daysUntilExpiry == 1 ? "" : "s")",
				message: "Certificate expires very soon",
				details: buildDetails(certInfo: certInfo, status: "EXPIRING SOON"),
				duration: duration,
				solutions: [
					"Certificate expires on \(formatDate(notAfter))",
					"Contact the broker administrator immediately",
					"Plan for certificate renewal"
				]
			)
		}

		if daysUntilExpiry <= 30 {
			return .warning(
				summary: "Expires in \(daysUntilExpiry) days",
				message: "Certificate expiring soon",
				details: buildDetails(certInfo: certInfo, status: "WARNING"),
				duration: duration,
				solutions: [
					"Certificate expires on \(formatDate(notAfter))",
					"Plan for certificate renewal",
					"Contact the broker administrator"
				]
			)
		}

		// Certificate is valid
		let validFor: String
		if daysUntilExpiry > 365 {
			let years = daysUntilExpiry / 365
			validFor = "Valid for \(years)+ year\(years == 1 ? "" : "s")"
		} else if daysUntilExpiry > 90 {
			let months = daysUntilExpiry / 30
			validFor = "Valid for \(months) month\(months == 1 ? "" : "s")"
		} else {
			validFor = "Valid for \(daysUntilExpiry) days"
		}

		return .success(
			summary: validFor,
			details: buildDetails(certInfo: certInfo, status: "VALID"),
			duration: duration
		)
	}

	private func buildDetails(certInfo: CertInfo, status: String) -> String {
		var details = "Certificate Validity: \(status)\n\n"

		if let cn = certInfo.commonName {
			details += "Subject: \(cn)\n"
		}

		if let issuer = certInfo.issuer {
			details += "Issuer: \(issuer)\n"
		}

		details += "\n"

		if let notBefore = certInfo.notBefore {
			details += "Valid From: \(formatDate(notBefore))\n"
		}

		if let notAfter = certInfo.notAfter {
			details += "Valid Until: \(formatDate(notAfter))\n"
		}

		return details
	}

	private func formatDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		return formatter.string(from: date)
	}

	private func formatTimeInterval(_ interval: TimeInterval) -> String {
		let days = Int(interval / 86400)
		if days > 0 {
			return "\(days) day\(days == 1 ? "" : "s")"
		}

		let hours = Int(interval / 3600)
		if hours > 0 {
			return "\(hours) hour\(hours == 1 ? "" : "s")"
		}

		let minutes = Int(interval / 60)
		return "\(minutes) minute\(minutes == 1 ? "" : "s")"
	}
}
