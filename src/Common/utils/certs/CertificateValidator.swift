//
//  CertificateValidator.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Validates certificates against hostnames and validates domain/IP formats
struct CertificateValidator {

	/// Check if hostname matches the certificate's CN or SANs
	static func hostnameMatches(_ hostname: String, certInfo: CertInfo) -> Bool {
		let lowerHostname = hostname.lowercased()

		// Check CN
		if let cn = certInfo.commonName?.lowercased() {
			if matchesPattern(lowerHostname, pattern: cn) {
				return true
			}
		}

		// Check SANs
		for san in certInfo.subjectAltNames where matchesPattern(lowerHostname, pattern: san.lowercased()) {
			return true
		}

		return false
	}

	/// Check if hostname matches a pattern (supports wildcards)
	static func matchesPattern(_ hostname: String, pattern: String) -> Bool {
		// Direct match
		if hostname == pattern {
			return true
		}

		// Wildcard match: *.example.com matches mqtt.example.com but NOT deep.sub.example.com
		// Standard wildcard only matches a single label
		if pattern.starts(with: "*.") {
			let suffix = String(pattern.dropFirst(2))
			// Check that hostname ends with .suffix AND has exactly one more label
			guard hostname.hasSuffix("." + suffix) else { return false }
			let prefix = String(hostname.dropLast(suffix.count + 1))
			// The prefix should be a single label (no dots)
			return !prefix.contains(".")
		}

		return false
	}

	/// Validates if a string looks like a valid domain name or IP address
	static func isValidDomainOrIP(_ str: String) -> Bool {
		guard !str.isEmpty else { return false }

		// Check if it's an IPv4 address
		let ipv4Pattern = "^([0-9]{1,3}\\.){3}[0-9]{1,3}$"
		if let regex = try? NSRegularExpression(pattern: ipv4Pattern),
		   regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) != nil {
			return true
		}

		// Check if it's an IPv6 address (simplified check for hex chars and colons)
		if str.contains(":") && str.allSatisfy({ $0.isHexDigit || $0 == ":" }) {
			return true
		}

		// Check if it's a valid domain name
		// Valid chars: alphanumeric, dots, hyphens, wildcards
		let domainPattern = "^(?:\\*\\.)?(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$"
		if let regex = try? NSRegularExpression(pattern: domainPattern),
		   regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) != nil {
			return true
		}

		return false
	}
}
