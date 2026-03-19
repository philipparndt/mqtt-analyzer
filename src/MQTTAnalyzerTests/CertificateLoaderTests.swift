//
//  CertificateLoaderTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class CertificateLoaderTests: XCTestCase {

	// MARK: - extractDERFromPEM tests

	func testExtractDERFromPEM_validPEM() {
		let pem = """
-----BEGIN CERTIFICATE-----
SGVsbG8gV29ybGQ=
-----END CERTIFICATE-----
"""
		let derData = CertificateLoader.extractDERFromPEM(pem)
		XCTAssertNotNil(derData)
		if let data = derData {
			XCTAssertEqual(String(data: data, encoding: .utf8), "Hello World")
		}
	}

	func testExtractDERFromPEM_multilinePEM() {
		let pem = """
-----BEGIN CERTIFICATE-----
SGVs
bG8g
V29y
bGQ=
-----END CERTIFICATE-----
"""
		let derData = CertificateLoader.extractDERFromPEM(pem)
		XCTAssertNotNil(derData)
		if let data = derData {
			XCTAssertEqual(String(data: data, encoding: .utf8), "Hello World")
		}
	}

	func testExtractDERFromPEM_invalidPEM() {
		let pem = "This is not a PEM certificate"
		let derData = CertificateLoader.extractDERFromPEM(pem)
		XCTAssertNil(derData)
	}

	func testExtractDERFromPEM_emptyContent() {
		let pem = """
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
"""
		let derData = CertificateLoader.extractDERFromPEM(pem)
		// Empty base64 should return empty data
		XCTAssertNotNil(derData)
		XCTAssertEqual(derData?.count, 0)
	}

	func testExtractDERFromPEM_missingEndMarker() {
		let pem = """
-----BEGIN CERTIFICATE-----
SGVsbG8gV29ybGQ=
"""
		// Should still extract (stops at end of content)
		let derData = CertificateLoader.extractDERFromPEM(pem)
		XCTAssertNotNil(derData)
	}

	// MARK: - HeuristicSANExtractor tests

	func testExtractSANsHeuristic_withDNSNames() {
		// Create a byte array with DNS name tag (0x82) followed by length and data
		// "example.com" = 11 bytes
		let dnsName = "example.com"
		var bytes: [UInt8] = [0x82, UInt8(dnsName.count)]
		bytes.append(contentsOf: dnsName.utf8)

		let sans = HeuristicSANExtractor.extract(from: bytes)
		XCTAssertEqual(sans.count, 1)
		XCTAssertEqual(sans.first, "example.com")
	}

	func testExtractSANsHeuristic_withIPv4() {
		// IP address tag (0x87) followed by length (4) and IPv4 bytes
		let bytes: [UInt8] = [0x87, 0x04, 192, 168, 1, 1] // NOSONAR — test IP address

		let sans = HeuristicSANExtractor.extract(from: bytes)
		XCTAssertEqual(sans.count, 1)
		XCTAssertEqual(sans.first, "192.168.1.1") // NOSONAR — test IP address
	}

	func testExtractSANsHeuristic_withIPv6() {
		// IP address tag (0x87) followed by length (16) and IPv6 bytes
		var bytes: [UInt8] = [0x87, 0x10]
		// Add 16 bytes for IPv6 (all zeros = ::)
		bytes.append(contentsOf: [0x20, 0x01, 0x0d, 0xb8, 0x00, 0x00, 0x00, 0x00,
								  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01])

		let sans = HeuristicSANExtractor.extract(from: bytes)
		XCTAssertEqual(sans.count, 1)
		XCTAssertTrue(sans.first?.contains(":") ?? false)
	}

	func testExtractSANsHeuristic_empty() {
		let bytes: [UInt8] = []
		let sans = HeuristicSANExtractor.extract(from: bytes)
		XCTAssertEqual(sans.count, 0)
	}

	func testExtractSANsHeuristic_multipleDNSNames() {
		var bytes: [UInt8] = []

		// First DNS name
		let name1 = "mqtt.example.com"
		bytes.append(0x82)
		bytes.append(UInt8(name1.count))
		bytes.append(contentsOf: name1.utf8)

		// Second DNS name
		let name2 = "api.example.com"
		bytes.append(0x82)
		bytes.append(UInt8(name2.count))
		bytes.append(contentsOf: name2.utf8)

		let sans = HeuristicSANExtractor.extract(from: bytes)
		XCTAssertEqual(sans.count, 2)
		XCTAssertTrue(sans.contains("mqtt.example.com"))
		XCTAssertTrue(sans.contains("api.example.com"))
	}

	// MARK: - SANSequenceParser tests

	func testParseSANSequence_withDNSName() {
		// SEQUENCE containing one dNSName
		// 30 0E 82 0C example.com (11 bytes)
		let dnsName = "example.com"
		var data: [UInt8] = [0x30, UInt8(2 + dnsName.count)] // SEQUENCE header
		data.append(0x82) // dNSName tag
		data.append(UInt8(dnsName.count))
		data.append(contentsOf: dnsName.utf8)

		let sans = SANSequenceParser.parse(data)
		XCTAssertEqual(sans.count, 1)
		XCTAssertEqual(sans.first, "example.com")
	}

	func testParseSANSequence_withIPv4() {
		// SEQUENCE containing one IPv4 address
		var data: [UInt8] = [0x30, 0x06] // SEQUENCE header (6 bytes content)
		data.append(0x87) // iPAddress tag
		data.append(0x04) // length 4
		data.append(contentsOf: [10, 0, 0, 1]) // NOSONAR — test IP address

		let sans = SANSequenceParser.parse(data)
		XCTAssertEqual(sans.count, 1)
		XCTAssertEqual(sans.first, "10.0.0.1") // NOSONAR — test IP address
	}

	func testParseSANSequence_emptySequence() {
		// Empty SEQUENCE
		let data: [UInt8] = [0x30, 0x00]

		let sans = SANSequenceParser.parse(data)
		XCTAssertEqual(sans.count, 0)
	}

	func testParseSANSequence_invalidTag() {
		// Invalid data (not a SEQUENCE)
		let data: [UInt8] = [0x02, 0x01, 0x05] // INTEGER 5

		let sans = SANSequenceParser.parse(data)
		XCTAssertEqual(sans.count, 0)
	}

	// MARK: - loadCertInfo tests

	func testLoadCertInfo_nonexistentPath() {
		let certInfo = CertificateLoader.loadCertInfo(from: "/nonexistent/path/cert.pem")
		XCTAssertNil(certInfo)
	}
}
