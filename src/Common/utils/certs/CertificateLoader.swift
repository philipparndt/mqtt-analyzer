//
//  CertificateLoader.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Security

/// Loads and parses X.509 certificates from PEM and DER formats
struct CertificateLoader {

	/// Load certificate info from a file path (supports PEM and DER formats)
	static func loadCertInfo(from path: String) -> CertInfo? {
		do {
			let data = try Data(contentsOf: URL(fileURLWithPath: path))

			// Try to parse PEM format first
			let certString = String(data: data, encoding: .utf8) ?? ""
			if certString.contains("BEGIN CERTIFICATE") {
				if let derData = extractDERFromPEM(certString) {
					return extractInfo(from: derData)
				}
			}

			// Try DER format directly
			return extractInfo(from: data)
		} catch {
			return nil
		}
	}

	/// Extract DER-encoded certificate data from PEM string
	static func extractDERFromPEM(_ pem: String) -> Data? {
		let lines = pem.split(separator: "\n")
		var base64 = ""
		var inCert = false
		var foundBegin = false

		for line in lines {
			if line.contains("BEGIN CERTIFICATE") {
				inCert = true
				foundBegin = true
				continue
			}
			if line.contains("END CERTIFICATE") {
				break
			}
			if inCert {
				base64 += String(line)
			}
		}

		// Return nil if no BEGIN CERTIFICATE marker was found
		guard foundBegin else { return nil }

		return Data(base64Encoded: base64)
	}

	/// Extract certificate info from DER-encoded data
	static func extractInfo(from data: Data) -> CertInfo? {
		guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
			return nil
		}

		var info = CertInfo()

		// Extract subject CN - this is available on all platforms
		if let summary = SecCertificateCopySubjectSummary(cert) as String? {
			info.commonName = summary
		}

		// Extract SANs by parsing the DER certificate directly
		info.subjectAltNames = SANExtractor.extractSANsFromDER(data)

		return info
	}

	/// Checks if certificate has Extended Key Usage extension with serverAuth
	static func checkServerAuthExtension(certData: Data) -> Bool {
		CertificateEKUChecker.checkServerAuthExtension(certData: certData)
	}
}

// MARK: - SAN Extraction

/// Extracts Subject Alternative Names from certificates
struct SANExtractor {

	/// Extracts Subject Alternative Names from DER-encoded X.509 certificate
	static func extractSANsFromDER(_ derData: Data) -> [String] {
		let bytes = [UInt8](derData)

		NSLog("DERParser: Starting SAN extraction from certificate (size: \(bytes.count) bytes)")

		// Try structured parsing first
		let structuredResult = extractSANsStructured(bytes)
		if !structuredResult.isEmpty {
			NSLog("DERParser: Found \(structuredResult.count) SANs via structured parsing")
			return structuredResult
		}

		// If structured parsing failed, try heuristic search
		NSLog("DERParser: Structured parsing found no SANs, trying heuristic search")
		let heuristicResult = HeuristicSANExtractor.extract(from: bytes)
		if !heuristicResult.isEmpty {
			NSLog("DERParser: Found \(heuristicResult.count) SANs via heuristic search")
			return heuristicResult
		}

		NSLog("DERParser: No SANs found by either method")
		return []
	}

	/// Structured ASN.1 parsing - follows X.509 certificate format
	static func extractSANsStructured(_ bytes: [UInt8]) -> [String] {
		var parser = DERParser(bytes: bytes)

		let tbsEnd = parser.skipToExtensions()
		guard tbsEnd > 0 else {
			NSLog("DERParser: Failed to parse certificate structure")
			return []
		}

		NSLog("DERParser: After parsing TBS fields, position=\(parser.position), tbsEnd=\(tbsEnd)")
		return findSANExtension(parser: &parser, bytes: bytes, tbsEnd: tbsEnd)
	}

	private static func findSANExtension(parser: inout DERParser, bytes: [UInt8], tbsEnd: Int) -> [String] {
		// Look for extensions [3] EXPLICIT
		guard parser.position < tbsEnd && parser.peek() == 0xa3 else { return [] }

		NSLog("DERParser: Found extensions [3]")
		parser.position += 1
		let extLength = parser.parseLength()
		let extEnd = parser.position + extLength
		NSLog("DERParser: Extensions block: length=\(extLength), end=\(extEnd)")

		// Extensions is a SEQUENCE
		guard parser.parseTag(0x30) else { return [] }
		let seqLength = parser.parseLength()
		let seqEnd = parser.position + seqLength
		NSLog("DERParser: Extensions SEQUENCE: length=\(seqLength), end=\(seqEnd)")

		return parseExtensionsForSAN(parser: &parser, bytes: bytes, seqEnd: seqEnd, extEnd: extEnd)
	}

	private static func parseExtensionsForSAN(
		parser: inout DERParser,
		bytes: [UInt8],
		seqEnd: Int,
		extEnd: Int
	) -> [String] {
		var extensionCount = 0

		while parser.position < seqEnd && parser.position < extEnd {
			guard parser.parseTag(0x30) else {
				NSLog("DERParser: Failed to parse Extension SEQUENCE tag")
				break
			}
			let extnLength = parser.parseLength()
			let extnEnd = parser.position + extnLength
			extensionCount += 1

			if let sans = parseSingleExtension(parser: &parser, bytes: bytes) {
				return sans
			}

			parser.position = extnEnd
		}

		NSLog("DERParser: Parsed \(extensionCount) extensions, SAN not found")
		return []
	}

	private static func parseSingleExtension(parser: inout DERParser, bytes: [UInt8]) -> [String]? {
		// OID (extnID)
		guard parser.parseTag(0x06) else {
			NSLog("DERParser: Failed to parse OID tag in extension")
			return nil
		}
		let oidLength = parser.parseLength()
		let oid = Array(bytes[parser.position..<parser.position + oidLength])
		parser.position += oidLength

		let oidHex = oid.map { String(format: "%02x", $0) }.joined(separator: " ")
		NSLog("DERParser: Extension OID: \(oidHex)")

		// Check if this is the SAN extension (2.5.29.17)
		guard oid == [0x55, 0x1d, 0x11] else { return nil }

		NSLog("DERParser: Found SAN extension!")
		return extractSANFromExtension(parser: &parser, bytes: bytes)
	}

	private static func extractSANFromExtension(parser: inout DERParser, bytes: [UInt8]) -> [String] {
		// Critical (BOOLEAN) - optional
		if parser.peek() == 0x01 {
			parser.position += 1
			let critLength = parser.parseLength()
			parser.position += critLength
		}

		// extnValue (OCTET STRING)
		guard parser.parseTag(0x04) else {
			NSLog("DERParser: Failed to parse SAN extnValue OCTET STRING tag")
			return []
		}
		let octetLength = parser.parseLength()
		NSLog("DERParser: SAN extnValue OCTET STRING length=\(octetLength)")
		let octetData = Array(bytes[parser.position..<parser.position + octetLength])
		let result = SANSequenceParser.parse(octetData)
		NSLog("DERParser: Extracted \(result.count) SANs: \(result)")
		return result
	}
}

// MARK: - Heuristic SAN Extraction

/// Heuristic-based SAN extraction - searches for DNS name patterns
struct HeuristicSANExtractor {

	static func extract(from bytes: [UInt8]) -> [String] {
		var sans: [String] = []

		NSLog("DERParser: Heuristic search - looking for 0x82 (dNSName) and 0x87 (iPAddress) tags")

		sans.append(contentsOf: extractDNSNames(from: bytes))
		sans.append(contentsOf: extractIPAddresses(from: bytes))

		return sans
	}

	private static func extractDNSNames(from bytes: [UInt8]) -> [String] {
		var names: [String] = []
		var found82Tags = 0

		guard bytes.count > 2 else { return names }

		for i in 0..<(bytes.count - 2) where bytes[i] == 0x82 {
			found82Tags += 1
			if let name = extractDNSName(from: bytes, at: i) {
				names.append(name)
			}
		}

		NSLog("DERParser: Found \(found82Tags) instances of 0x82 tag")
		return names
	}

	private static func extractDNSName(from bytes: [UInt8], at index: Int) -> String? {
		let length = Int(bytes[index + 1])
		NSLog(String(format: "DERParser: Found 0x82 tag at offset %d, length=%d", index, length))

		guard length > 0 && length < 256 && index + 2 + length <= bytes.count else { return nil }

		guard let name = String(bytes: bytes[index + 2..<index + 2 + length], encoding: .ascii) else { return nil }

		// Validate it looks like a DNS name
		guard !name.isEmpty && !name.contains("\0") else { return nil }

		NSLog("DERParser: Heuristic found dNSName: \(name)")
		return name
	}

	private static func extractIPAddresses(from bytes: [UInt8]) -> [String] {
		var addresses: [String] = []

		guard bytes.count > 2 else { return addresses }

		for i in 0..<(bytes.count - 2) where bytes[i] == 0x87 {
			if let address = extractIPAddress(from: bytes, at: i) {
				addresses.append(address)
			}
		}

		return addresses
	}

	private static func extractIPAddress(from bytes: [UInt8], at index: Int) -> String? {
		let length = Int(bytes[index + 1])

		if length == 4 && index + 6 <= bytes.count {
			let octets = Array(bytes[index + 2..<index + 6])
			let ipv4 = "\(octets[0]).\(octets[1]).\(octets[2]).\(octets[3])"
			NSLog("DERParser: Heuristic found IPv4: \(ipv4)")
			return ipv4
		} else if length == 16 && index + 18 <= bytes.count {
			let ipv6 = formatIPv6(bytes: bytes, startIndex: index + 2)
			NSLog("DERParser: Heuristic found IPv6: \(ipv6)")
			return ipv6
		}

		return nil
	}

	private static func formatIPv6(bytes: [UInt8], startIndex: Int) -> String {
		var parts: [String] = []
		for j in stride(from: 0, to: 16, by: 2) {
			let val = UInt16(bytes[startIndex + j]) << 8 | UInt16(bytes[startIndex + j + 1])
			parts.append(String(format: "%x", val))
		}
		return parts.joined(separator: ":")
	}
}

// MARK: - SAN Sequence Parser

/// Parses the SEQUENCE OF GeneralName inside the SAN extension value
struct SANSequenceParser {

	static func parse(_ data: [UInt8]) -> [String] {
		var sans: [String] = []
		var parser = DERParser(bytes: data)

		NSLog("DERParser: parseSANSequence: data size=\(data.count)")

		guard parser.parseTag(0x30) else {
			NSLog("DERParser: parseSANSequence: Failed to parse SEQUENCE tag")
			return []
		}
		let seqLength = parser.parseLength()
		let seqEnd = parser.position + seqLength
		NSLog("DERParser: parseSANSequence: SEQUENCE length=\(seqLength), end=\(seqEnd)")

		while parser.position < seqEnd {
			if let san = parseGeneralName(parser: &parser, data: data) {
				sans.append(san)
			}
		}

		NSLog("DERParser: parseSANSequence: Extracted \(sans.count) SANs total")
		return sans
	}

	private static func parseGeneralName(parser: inout DERParser, data: [UInt8]) -> String? {
		let tag = parser.peek()
		NSLog("DERParser: parseSANSequence: Processing GeneralName with tag=0x\(String(format: "%02x", tag))")

		switch tag {
		case 0x82: return parseDNSName(parser: &parser, data: data)
		case 0x87: return parseIPAddress(parser: &parser, data: data)
		case 0x86: return parseURI(parser: &parser, data: data)
		case 0x81: return parseEmail(parser: &parser, data: data)
		default:
			NSLog("DERParser: Unknown GeneralName tag: 0x\(String(format: "%02x", tag))")
			parser.position += 1
			let skipLength = parser.parseLength()
			parser.position += skipLength
			return nil
		}
	}

	private static func parseDNSName(parser: inout DERParser, data: [UInt8]) -> String? {
		parser.position += 1
		let nameLength = parser.parseLength()
		defer { parser.position += nameLength }

		guard let name = String(bytes: data[parser.position..<min(parser.position + nameLength, data.count)], encoding: .ascii) else {
			return nil
		}

		let trimmedName = name.trimmingCharacters(in: .whitespaces)
		guard !trimmedName.isEmpty && !trimmedName.contains("\0") else { return nil }

		NSLog("DERParser: dNSName: \(trimmedName)")
		return trimmedName
	}

	private static func parseIPAddress(parser: inout DERParser, data: [UInt8]) -> String? {
		parser.position += 1
		let ipLength = parser.parseLength()
		defer { parser.position += ipLength }

		if ipLength == 4 {
			let octets = Array(data[parser.position..<min(parser.position + 4, data.count)])
			let ipv4 = "\(octets[0]).\(octets[1]).\(octets[2]).\(octets[3])"
			NSLog("DERParser: iPAddress (IPv4): \(ipv4)")
			return ipv4
		} else if ipLength == 16 {
			var parts: [String] = []
			for i in stride(from: 0, to: 16, by: 2) {
				let val = UInt16(data[parser.position + i]) << 8 | UInt16(data[parser.position + i + 1])
				parts.append(String(format: "%x", val))
			}
			let ipv6 = parts.joined(separator: ":")
			NSLog("DERParser: iPAddress (IPv6): \(ipv6)")
			return ipv6
		}

		return nil
	}

	private static func parseURI(parser: inout DERParser, data: [UInt8]) -> String? {
		parser.position += 1
		let uriLength = parser.parseLength()
		defer { parser.position += uriLength }

		guard let uri = String(bytes: data[parser.position..<min(parser.position + uriLength, data.count)], encoding: .ascii) else {
			return nil
		}

		NSLog("DERParser: uniformResourceIdentifier: \(uri)")
		return uri
	}

	private static func parseEmail(parser: inout DERParser, data: [UInt8]) -> String? {
		parser.position += 1
		let emailLength = parser.parseLength()
		defer { parser.position += emailLength }

		guard let email = String(bytes: data[parser.position..<min(parser.position + emailLength, data.count)], encoding: .ascii) else {
			return nil
		}

		NSLog("DERParser: rfc822Name: \(email)")
		return email
	}
}
