//
//  CertificateValidatorTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

class CertificateValidatorTests: XCTestCase {

	// MARK: - hostnameMatches tests

	func testHostnameMatches_exactMatch() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["mqtt.example.com"]

		XCTAssertTrue(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_cnMatch() {
		var certInfo = CertInfo()
		certInfo.commonName = "mqtt.example.com"

		XCTAssertTrue(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_wildcardMatch() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["*.example.com"]

		XCTAssertTrue(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
		XCTAssertTrue(CertificateValidator.hostnameMatches("api.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_wildcardNoMatchApex() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["*.example.com"]

		// Wildcard should NOT match the apex domain
		XCTAssertFalse(CertificateValidator.hostnameMatches("example.com", certInfo: certInfo))
	}

	func testHostnameMatches_wildcardNoMatchDeepSubdomain() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["*.example.com"]

		// Standard wildcard does not match nested subdomains
		XCTAssertFalse(CertificateValidator.hostnameMatches("deep.sub.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_caseInsensitive() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["MQTT.Example.COM"]

		XCTAssertTrue(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
		XCTAssertTrue(CertificateValidator.hostnameMatches("MQTT.EXAMPLE.COM", certInfo: certInfo))
	}

	func testHostnameMatches_noMatch() {
		var certInfo = CertInfo()
		certInfo.commonName = "other.example.com"
		certInfo.subjectAltNames = ["api.example.com"]

		XCTAssertFalse(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_multipleSANs() {
		var certInfo = CertInfo()
		certInfo.subjectAltNames = ["api.example.com", "mqtt.example.com", "www.example.com"]

		XCTAssertTrue(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
	}

	func testHostnameMatches_emptyCertInfo() {
		let certInfo = CertInfo()

		XCTAssertFalse(CertificateValidator.hostnameMatches("mqtt.example.com", certInfo: certInfo))
	}

	// MARK: - matchesPattern tests

	func testMatchesPattern_exactMatch() {
		XCTAssertTrue(CertificateValidator.matchesPattern("example.com", pattern: "example.com"))
	}

	func testMatchesPattern_wildcard() {
		XCTAssertTrue(CertificateValidator.matchesPattern("sub.example.com", pattern: "*.example.com"))
	}

	func testMatchesPattern_wildcardNoMatchApex() {
		XCTAssertFalse(CertificateValidator.matchesPattern("example.com", pattern: "*.example.com"))
	}

	func testMatchesPattern_noMatch() {
		XCTAssertFalse(CertificateValidator.matchesPattern("other.com", pattern: "example.com"))
	}

	// MARK: - isValidDomainOrIP tests

	func testIsValidDomainOrIP_validDomain() {
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("example.com"))
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("sub.example.com"))
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("my-host.example.com"))
	}

	func testIsValidDomainOrIP_wildcardDomain() {
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("*.example.com"))
	}

	func testIsValidDomainOrIP_validIPv4() {
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("192.168.1.1")) // NOSONAR
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("10.0.0.1")) // NOSONAR
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("255.255.255.255"))
	}

	func testIsValidDomainOrIP_validIPv6() {
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("2001:db8:85a3:0:0:8a2e:370:7334")) // NOSONAR
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("fe80:0:0:0:0:0:0:1")) // NOSONAR
	}

	func testIsValidDomainOrIP_invalid() {
		XCTAssertFalse(CertificateValidator.isValidDomainOrIP(""))
		XCTAssertFalse(CertificateValidator.isValidDomainOrIP("   "))
		XCTAssertFalse(CertificateValidator.isValidDomainOrIP("not a domain!"))
		XCTAssertFalse(CertificateValidator.isValidDomainOrIP("has spaces.com"))
	}

	func testIsValidDomainOrIP_singleLabel() {
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("localhost"))
		XCTAssertTrue(CertificateValidator.isValidDomainOrIP("myhost"))
	}
}
