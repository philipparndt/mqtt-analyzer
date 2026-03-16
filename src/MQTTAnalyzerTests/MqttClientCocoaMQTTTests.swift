//
//  MqttClientCocoaMQTTTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 08.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import Network
import CocoaMQTT
@testable import MQTTAnalyzer

class MqttClientCocoaMQTTTests: XCTestCase {

	func testInvalidHostname_summary() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorSummary(error: NSError(domain: "", code: 8))
		XCTAssertEqual("Invalid hostname", msg)
	}

	func testInvalidHostname_details() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorDetails(error: NSError(domain: "", code: 8))
		XCTAssertTrue(msg.contains("hostname appears to be invalid"), msg)
	}

	func testConnectionRefused() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorSummary(error: NWError.posix(POSIXErrorCode.ECONNREFUSED))
		XCTAssertTrue(msg.contains("Connection refused"), msg)
	}

	func testConnectionTLS() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorDetails(error: NWError.tls(-9407))
		XCTAssertTrue(msg.contains("-9407"), msg)
	}

	func testConnectionTLSBadCertificate_summary() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorSummary(error: NWError.tls(-9808))
		XCTAssertTrue(msg.contains("Certificate validation failed"), msg)
	}

	func testConnectionTLSBadCertificate_details() throws {
		let msg = ClientUtils<CocoaMQTT5, CocoaMQTT5Message>.extractErrorDetails(error: NWError.tls(-9808))
		XCTAssertTrue(msg.contains("CERTIFICATE") || msg.contains("certificate"), msg)
	}

}
