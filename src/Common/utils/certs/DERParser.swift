//
//  DERParser.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// ASN.1/DER binary parser for X.509 certificate parsing
struct DERParser {
	let bytes: [UInt8]
	var position: Int = 0

	init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	/// Peek at the current byte without advancing position
	func peek() -> UInt8 {
		guard position < bytes.count else { return 0 }
		return bytes[position]
	}

	/// Parse an expected tag, returning true if matched and advancing position
	mutating func parseTag(_ expectedTag: UInt8) -> Bool {
		guard position < bytes.count && bytes[position] == expectedTag else { return false }
		position += 1
		return true
	}

	/// Parse a DER length field (supports short and long forms)
	mutating func parseLength() -> Int {
		guard position < bytes.count else { return 0 }

		let firstByte = bytes[position]
		position += 1

		if firstByte & 0x80 == 0 {
			// Short form: length is directly in the byte
			return Int(firstByte)
		} else {
			// Long form: lower 7 bits indicate number of length bytes
			let numBytes = Int(firstByte & 0x7f)
			guard position + numBytes <= bytes.count else { return 0 }

			var length = 0
			for i in 0..<numBytes {
				length = (length << 8) | Int(bytes[position + i])
			}
			position += numBytes
			return length
		}
	}

	/// Skip a field with expected tag, returning the length skipped
	mutating func skipField(tag: UInt8) -> Int {
		if parseTag(tag) {
			let length = parseLength()
			position += length
			return length
		}
		return 0
	}

	/// Skip TBSCertificate header fields to reach extensions
	/// Returns the tbsEnd position, or -1 on failure
	mutating func skipToExtensions() -> Int {
		// Certificate is a SEQUENCE
		guard parseTag(0x30) else { return -1 }
		_ = parseLength()

		// TBSCertificate is a SEQUENCE
		guard parseTag(0x30) else { return -1 }
		let tbsLength = parseLength()
		let tbsEnd = position + tbsLength

		// Version [0] (optional)
		if peek() == 0xa0 {
			position += 1
			let verLength = parseLength()
			position += verLength
		}

		// SerialNumber (INTEGER)
		_ = skipField(tag: 0x02)

		// Signature Algorithm (SEQUENCE)
		_ = skipField(tag: 0x30)

		// Issuer (Name/SEQUENCE)
		_ = skipField(tag: 0x30)

		// Validity (SEQUENCE)
		_ = skipField(tag: 0x30)

		// Subject (Name/SEQUENCE)
		_ = skipField(tag: 0x30)

		// SubjectPublicKeyInfo (SEQUENCE)
		_ = skipField(tag: 0x30)

		return tbsEnd
	}
}
