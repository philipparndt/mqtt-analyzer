//
//  CertificateEKUCheckerTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2026-03-18.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import XCTest
@testable import MQTTAnalyzer

final class CertificateEKUCheckerTests: XCTestCase {

	// MARK: - AWS IoT certificate (has serverAuth EKU)

	func testAWSIoTCertificateHasServerAuth() {
		let certData = Data(base64Encoded: Self.awsIoTCertBase64)!
		let result = CertificateEKUChecker.checkEKU(certData: certData)
		XCTAssertEqual(result, .serverAuthPresent,
					   "AWS IoT certificate should have serverAuth EKU")
	}

	func testAWSIoTCertificateBoolCheck() {
		let certData = Data(base64Encoded: Self.awsIoTCertBase64)!
		XCTAssertTrue(CertificateEKUChecker.checkServerAuthExtension(certData: certData))
	}

	// MARK: - Self-signed certificate without EKU extension

	func testCertWithoutEKUExtension() {
		let certData = Data(base64Encoded: Self.noEKUCertBase64)!
		let result = CertificateEKUChecker.checkEKU(certData: certData)
		XCTAssertEqual(result, .noEKUExtension,
					   "Certificate without EKU extension should return .noEKUExtension")
	}

	func testCertWithoutEKUBoolCheckReturnsFalse() {
		let certData = Data(base64Encoded: Self.noEKUCertBase64)!
		XCTAssertFalse(CertificateEKUChecker.checkServerAuthExtension(certData: certData),
					   "Bool check returns false for missing EKU (no serverAuth present)")
	}

	// MARK: - Certificate with EKU but only clientAuth (no serverAuth)

	func testCertWithClientAuthOnlyEKU() {
		let certData = Data(base64Encoded: Self.clientAuthOnlyCertBase64)!
		let result = CertificateEKUChecker.checkEKU(certData: certData)
		XCTAssertEqual(result, .serverAuthMissing,
					   "Certificate with clientAuth-only EKU should return .serverAuthMissing")
	}

	// MARK: - Invalid data

	func testInvalidDataReturnsParseError() {
		let certData = Data([0x00, 0x01, 0x02, 0x03])
		let result = CertificateEKUChecker.checkEKU(certData: certData)
		XCTAssertEqual(result, .parseError)
	}

	func testEmptyDataReturnsParseError() {
		let result = CertificateEKUChecker.checkEKU(certData: Data())
		XCTAssertEqual(result, .parseError)
	}

	// MARK: - Test certificates (base64-encoded DER)

	// AWS IoT: *.iot.eu-central-1.amazonaws.com
	// Has EKU with serverAuth + clientAuth
	// swiftlint:disable:next line_length
	static let awsIoTCertBase64 = "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"

	// Self-signed cert without EKU extension
	// swiftlint:disable:next line_length
	static let noEKUCertBase64 = "MIIDCzCCAfOgAwIBAgIUCKbUQXjm4jfEfh10H3jabJHwR3owDQYJKoZIhvcNAQELBQAwFTETMBEGA1UEAwwKdGVzdC5sb2NhbDAeFw0yNjAzMTgxMzE3MjZaFw0yNjAzMTkxMzE3MjZaMBUxEzARBgNVBAMMCnRlc3QubG9jYWwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCQy7jtO+QBSuDwZHfRdjy00QILb16cj7KY6C6pxTsKzPpS6s6FvAglBgomG4st/0IwXGCoHethI2nOylqRmMTTyhxYx9JkHmBV8Jx5+LhsH7q0Z4nCsX8ExDGjbSyFyBwSwZ93dMZQzbU5pzdxRdxbrhiswWz88GhZHrqriY9k/AR7H9YRGrBeS5jk6Rg7bYXc2w9l3zs4TnhJnCJN8hT8FZPr1Vh5C8KdJ0xAZLaaLGZC5a2hoqwPWA2zJURfyOo4ad8918H63ILLwr0ywPCGcQq9JaCCsZs97+pab7m3Knwl/I7g2dlnX2ZfWd5Pkk6Z8wV7KHcBtIQk51JwCij3AgMBAAGjUzBRMB0GA1UdDgQWBBS2tHxlEFVJMenYPjdiBz7UBsiLzjAfBgNVHSMEGDAWgBS2tHxlEFVJMenYPjdiBz7UBsiLzjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQALPz9NZp99Eozi91EEPtgCARbWhFyP6uODP2bTAffW+TqPHVmMy6Xjwm5SwM4x1IBqy9nOQsWMix54vdq8MqTR5G5XfduyZWNzxyWuCNFEXIROdrlywxW3ogWWO0T6xJMycfen7ChYlE2Zqo3AxOC/VKbtaEemN8hmaN+Z5oXVqMzToPO9xLMUQL6iRBQvAi9zpS/LDzepymOdr2Y5VKf/6jkXEoAoK7nt7jpHeTsyMV0iZUf8BF9DAkkwPfjrIPPnd4o9AYdLXzYt/gKRsnoO9ZDodmkR70S+JZtFFiME4iXU8x6zWeNP/BHE71I6dW0nyi0JLP2+OqdL5FabtE0M"

	// Self-signed cert with EKU containing only clientAuth (no serverAuth)
	// swiftlint:disable:next line_length
	static let clientAuthOnlyCertBase64 = "MIIDIDCCAgigAwIBAgIUexYQSN5G7wc+TNaOa4ewafcWGyMwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UEAwwKdGVzdC5sb2NhbDAeFw0yNjAzMTgxMzE3NDZaFw0yNjAzMTkxMzE3NDZaMBUxEzARBgNVBAMMCnRlc3QubG9jYWwwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTGfgnmvs2/AbBC3DLksu1DsEh3oqo5Wvm7G4BcRDeLrE9/ZpabWLtI8dQsWIz/phNL4C3QwgYOsHbocabTrIu39EfxEXqrXABu0vSYAOSWPnzq0rir/5rPDk3eqfeoiN/paV1D0GjBvD0jyf4sdtC4lUM5IC7YtdheY5Z2u7iqJZC5z+QptHp0H/EEEG/Umaf8GVB2TRoHqlV5zinvRqpqZQhdQFqpLzX9Uycsst/M/tUvU22V3dVDxd+eK0Rjde4TIjT4wAVFOQ/D6k8IDEoQf9Y6pLpJDzhO9MGddSk8REC+yy6iPLKGXJdSf8BrwzrE9qyZ2FUMzHBK7a09G57AgMBAAGjaDBmMB0GA1UdDgQWBBTw5Qa+thvNcsB2lWfMbH8MEVRDoDAfBgNVHSMEGDAWgBTw5Qa+thvNcsB2lWfMbH8MEVRDoDAPBgNVHRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBCwUAA4IBAQA0wkP8O+bDAXk7KOzATn7IXFzjL3cIZEQTPHPMJO/raXbonVtPSorKTL4N+e838vxFc6mP6i4oBboMd4DS2DCFLz5N7lgSJZ/K3wcEvX2oXIWlVPD5BEh6SDZ8nZtA5YsX5eahEBJqElqYFyO1QEIiFnAth03udvs5wj7u684KqUcQq6UFxlUSPaHF/R01qVy9Jv2lzc+lx5xpMTO6LonscPNq0txa26hQH3lBDkCwy9NJQvDAFwm1lFuSsZGDskglyMkSfs7xSjQjup6LRQfkciL/iXoCeqHaaZ0ip9EORhcOcdwxX0A8xLKCojdXuKoD2vIji8ZIJnbck2Pj+VPx"
}
