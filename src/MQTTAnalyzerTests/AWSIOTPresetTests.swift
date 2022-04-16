//
//  AWSIOTPresetTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2020-05-09.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
@testable import MQTTAnalyzer

class AWSIOTPresetTests: XCTestCase {

	func testNoSuggestChangeForOtherHosts() {
		var model = HostFormModel()
		model.hostname = "piiot"
		XCTAssertFalse(model.suggestAWSIOTChanges())
		model.hostname = "test.mosquitto.org"
		XCTAssertFalse(model.suggestAWSIOTChanges())
	}
	
	func testSuggestChange() {
		var model = HostFormModel()
		model.hostname = "1234-ats.iot.some.amazonaws.com"
		XCTAssert(model.suggestAWSIOTChanges())
	}
	
	func testNoSuggestChangeAfterApply() {
		var model = HostFormModel()
		model.hostname = "1234-ats.iot.some.amazonaws.com"
		model.updateSettingsForAWSIOT()
		XCTAssertFalse(model.suggestAWSIOTChanges())
	}
	
	func testSettingsAfterApply() {
		var model = HostFormModel()
		model.hostname = "1234-ats.iot.some.amazonaws.com"
		model.updateSettingsForAWSIOT()
		XCTAssertEqual("8883", model.port)
		XCTAssertEqual(true, model.ssl)
		XCTAssertEqual(false, model.untrustedSSL)
		XCTAssertEqual(HostProtocol.mqtt, model.protocolMethod)
		XCTAssertEqual(HostAuthenticationType.certificate, model.authType)
		XCTAssertEqual(HostClientImplType.cocoamqtt, model.clientImpl)
	}
	
}
