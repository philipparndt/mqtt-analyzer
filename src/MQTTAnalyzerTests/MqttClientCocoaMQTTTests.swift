//
//  MqttClientCocoaMQTTTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 08.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import Network
@testable import MQTTAnalyzer

class MqttClientCocoaMQTTTests: XCTestCase {
	 
	func testInvalidHostname() throws {
		let msg = MqttClientCocoaMQTT.extractErrorMessage(error: NSError(domain: "", code: 8))
		XCTAssertEqual("Invalid hostname.\nThe operation couldn’t be completed. ( error 8.)", msg)
	}
	
    func testConnectionRefused() throws {
		let msg = MqttClientCocoaMQTT.extractErrorMessage(error: NWError.posix(POSIXErrorCode.ECONNREFUSED))
		XCTAssertTrue(msg.contains("Connection refused"), msg)
	}
	
	func testConnectionTLS() throws {
		let msg = MqttClientCocoaMQTT.extractErrorMessage(error: NWError.tls(-9407))
		XCTAssertEqual("Network.NWError: -9407: Optional(OSStatus -9407)", msg)
	}

}
