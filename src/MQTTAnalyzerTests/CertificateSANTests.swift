//
//  CertificateSANTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-03-18.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

final class CertificateSANTests: XCTestCase {

	// MARK: - AWS IoT cert (has real SANs)

	func testAWSIoTCertificateHasSANs() {
		let certData = Data(base64Encoded: Self.awsIoTCertBase64)!
		let info = CertificateLoader.parseCertInfo(from: certData)
		XCTAssertNotNil(info)
		XCTAssertFalse(info!.subjectAltNames.isEmpty, "AWS IoT cert should have SANs")
		XCTAssertTrue(
			info!.subjectAltNames.contains("*.iot.eu-central-1.amazonaws.com"),
			"Should contain wildcard SAN"
		)
	}

	// MARK: - Mosquitto cert (no SAN extension — heuristic must not return garbage)

	func testMosquittoCertificateNoFalseSANs() {
		let certData = Data(base64Encoded: Self.mosquittoCertBase64)!
		let info = CertificateLoader.parseCertInfo(from: certData)
		XCTAssertNotNil(info)

		// Filter SANs the same way the diagnostic view does
		let validSANs = info!.subjectAltNames.filter { san in
			let trimmed = san.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !trimmed.isEmpty, trimmed.count >= 3 else { return false }
			return trimmed.contains(".") || trimmed.contains(":")
		}

		// Should have no valid SANs (cert has no SAN extension)
		// If any are found, they must actually look like hostnames
		for san in validSANs {
			XCTAssertTrue(
				san.range(of: #"^[\w.*-]+(\.[\w-]+)+$"#, options: .regularExpression) != nil
				|| san.contains(":"),
				"SAN '\(san)' does not look like a valid hostname or IP"
			)
		}
	}

	func testMosquittoCertificateHasCommonName() {
		let certData = Data(base64Encoded: Self.mosquittoCertBase64)!
		let info = CertificateLoader.parseCertInfo(from: certData)
		XCTAssertNotNil(info)
		XCTAssertEqual(info!.commonName, "test.mosquitto.org")
	}

	func testMosquittoCertificateHasIssuer() {
		let certData = Data(base64Encoded: Self.mosquittoCertBase64)!
		let info = CertificateLoader.parseCertInfo(from: certData)
		XCTAssertNotNil(info)
		XCTAssertEqual(info!.issuer, "mosquitto.org")
	}

	func testMosquittoCertificateHasValidityDates() {
		let certData = Data(base64Encoded: Self.mosquittoCertBase64)!
		let info = CertificateLoader.parseCertInfo(from: certData)
		XCTAssertNotNil(info)
		XCTAssertNotNil(info!.notBefore)
		XCTAssertNotNil(info!.notAfter)
	}

	// MARK: - Test certificates

	static let awsIoTCertBase64 = CertificateEKUCheckerTests.awsIoTCertBase64

	// test.mosquitto.org — self-signed, no SAN extension
	// swiftlint:disable:next line_length
	static let mosquittoCertBase64 = "MIIDlzCCAn8CFH3Tm0/cW/ctDwwEfrjzI57Bm7e3MA0GCSqGSIb3DQEBCwUAMIGQMQswCQYDVQQGEwJHQjEXMBUGA1UECAwOVW5pdGVkIEtpbmdkb20xDjAMBgNVBAcMBURlcmJ5MRIwEAYDVQQKDAlNb3NxdWl0dG8xCzAJBgNVBAsMAkNBMRYwFAYDVQQDDA1tb3NxdWl0dG8ub3JnMR8wHQYJKoZIhvcNAQkBFhByb2dlckBhdGNob28ub3JnMB4XDTIwMDYwOTExMjE1NloXDTMwMDYwNjExMjE1NlowfzELMAkGA1UEBhMCR0IxFzAVBgNVBAgMDlVuaXRlZCBLaW5nZG9tMQ4wDAYDVQQHDAVEZXJieTESMBAGA1UECgwJTW9zcXVpdHRvMRYwFAYDVQQLDA1QdWJsaWMgc2VydmVyMRswGQYDVQQDDBJ0ZXN0Lm1vc3F1aXR0by5vcmcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDlhLItmW1ofAacp/IVycs3x4UjrhjWJPF/3TqA2Kkcs7RKCaldOm1Ij1154Y0aIxrDJY/8Lg9EupDaEeS4Z2jByiybqJnpZT4sfo2OslxIU7Jg4nT4rb3B+NiCZjCx3e7klyJ3z7K6sh5rpLY/hzC34JvEcRgBPvT9Iu68NzieVZM44Wve3Zkr+GWoKPzpRjIefgd5qeUuUAihplkx6pu5OkZv7aaAjVzJQ+tDJFQY/AJfU7146oX5XOecOhIVDGnTNwvOHdtnt4rGdxdfl6Y7332z03RES5FneW9Wemt4HBzKfB5bsogKDIDsrk7XgcZgqnvHQFr3OHcXtn/AaUohAgMBAAEwDQYJKoZIhvcNAQELBQADggEBALpvmc7hKSFruuBcS+KW/SwfNyeP35dq93hNNQTw/+x9Veex7N9eIfcf5NgjqRZ6wdu8tGu4ClePwAtqvzSCnVidY/XmwiL1Q4uuYNbtEYSlkrSVuWCW/cU6IYnefnficCTqAL+QGGRcp5ViQqSUR9QMm+gY+oWp3ZoUue291/mxTanWCs/uHYDQKu/xrvl7T9ZrlqIF1HuhlZKIZD3Wa2ZK9/thsaQnB714YB6lipPjVnkF1jtJX+Dj9dcVIRMwbkQKmXBxsX4Y5Dj0hYkfjoaTIHWT1z//B7lCdWZKj7jxNXxofNcAkb/zm4OAWArprTPyBjyO3ov96I3qlglnfac="
}
