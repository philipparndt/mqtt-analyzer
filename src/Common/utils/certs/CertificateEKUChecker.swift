//
//  CertificateEKUChecker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Checks Extended Key Usage extensions in X.509 certificates
struct CertificateEKUChecker {

	/// OID for Extended Key Usage extension (2.5.29.37)
	private static let ekuExtensionOID: [UInt8] = [0x55, 0x1d, 0x25]

	/// OID for serverAuth (1.3.6.1.5.5.7.3.1)
	private static let serverAuthOID: [UInt8] = [0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01]

	/// Result of the EKU check
	enum EKUResult: Equatable {
		/// EKU extension present with serverAuth
		case serverAuthPresent
		/// EKU extension present but serverAuth missing
		case serverAuthMissing
		/// No EKU extension in certificate (valid for all purposes per RFC 5280)
		case noEKUExtension
		/// Could not parse certificate
		case parseError
	}

	/// Checks if certificate has Extended Key Usage extension with serverAuth
	static func checkServerAuthExtension(certData: Data) -> Bool {
		return checkEKU(certData: certData) == .serverAuthPresent
	}

	/// Detailed EKU check returning the specific result
	static func checkEKU(certData: Data) -> EKUResult {
		let bytes = [UInt8](certData)
		var parser = DERParser(bytes: bytes)

		let tbsEnd = parser.skipToExtensions()
		guard tbsEnd > 0 else { return .parseError }

		return findServerAuthInExtensions(parser: &parser, bytes: bytes, tbsEnd: tbsEnd)
	}

	private static func findServerAuthInExtensions(
		parser: inout DERParser, bytes: [UInt8], tbsEnd: Int
	) -> EKUResult {
		// Look for extensions [3] EXPLICIT
		guard parser.position < tbsEnd && parser.peek() == 0xa3 else {
			return .noEKUExtension
		}

		parser.position += 1
		let extLength = parser.parseLength()
		let extEnd = parser.position + extLength

		// Extensions is a SEQUENCE
		guard parser.parseTag(0x30) else { return .parseError }
		let seqLength = parser.parseLength()
		let seqEnd = parser.position + seqLength

		// Parse each Extension
		while parser.position < seqEnd && parser.position < extEnd {
			if let found = parseExtensionForEKU(parser: &parser, bytes: bytes) {
				return found ? .serverAuthPresent : .serverAuthMissing
			}
		}

		// EKU extension not found among the extensions
		return .noEKUExtension
	}

	private static func parseExtensionForEKU(parser: inout DERParser, bytes: [UInt8]) -> Bool? {
		guard parser.parseTag(0x30) else { return nil }
		let extnLength = parser.parseLength()
		let extnEnd = parser.position + extnLength

		// OID (extnID)
		guard parser.parseTag(0x06) else { return nil }
		let oidLength = parser.parseLength()
		let oid = Array(bytes[parser.position..<parser.position + oidLength])
		parser.position += oidLength

		// Check if this is the EKU extension
		if oid == ekuExtensionOID {
			return checkEKUContent(parser: &parser, bytes: bytes)
		}

		// Not the EKU extension — skip and continue searching
		parser.position = extnEnd
		return nil
	}

	private static func checkEKUContent(parser: inout DERParser, bytes: [UInt8]) -> Bool {
		// Critical (BOOLEAN) - optional
		if parser.peek() == 0x01 {
			parser.position += 1
			let critLength = parser.parseLength()
			parser.position += critLength
		}

		// extnValue (OCTET STRING)
		guard parser.parseTag(0x04) else { return false }
		let octetLength = parser.parseLength()
		let ekuData = Array(bytes[parser.position..<parser.position + octetLength])

		return containsServerAuthOID(ekuData)
	}

	private static func containsServerAuthOID(_ ekuData: [UInt8]) -> Bool {
		guard ekuData.count >= serverAuthOID.count else { return false }

		for i in 0...(ekuData.count - serverAuthOID.count)
			where Array(ekuData[i..<i + serverAuthOID.count]) == serverAuthOID {
			return true
		}
		return false
	}
}
