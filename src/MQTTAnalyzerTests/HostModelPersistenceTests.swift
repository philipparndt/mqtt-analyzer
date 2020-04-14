//
//  HostModelPersistenceTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2020-02-28.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
@testable import MQTTAnalyzer

class HostModelPersistenceTests: XCTestCase, InitHost {
	func initHost(host: Host) {
		
	}
		
	func testTransformFromPersistenceModel() {
		let model = HostsModel(initMethod: self)
		
		let setting = HostSetting()
		setting.alias = "alias"
		setting.hostname = "hostname"
		setting.port = 1
		setting.topic = "topic"
		setting.qos = 2
		setting.authType = AuthenticationType.CERTIFICATE
		setting.username = "username"
		setting.password = "password"
		
		setting.certServerCA = "certServerCA"
		setting.certClient = "certClient"
		setting.certClientKey = "certClientKey"
		setting.certClientKeyPassword = "certClientKeyPassword"

		setting.clientID = "clientID"

		setting.limitTopic = 4
		setting.limitMessagesBatch = 5
		
		let persistence = HostsModelPersistence(model: model)
		let transformed = persistence.transform(setting)
		XCTAssertEqual("alias", transformed.alias)
		XCTAssertEqual("hostname", transformed.hostname)
		XCTAssertEqual(1, transformed.port)
		XCTAssertEqual("topic", transformed.topic)
		XCTAssertEqual(2, transformed.qos)
		XCTAssertEqual("username", transformed.username)
		XCTAssertEqual("password", transformed.password)
		XCTAssertEqual("certServerCA", transformed.certServerCA)
		XCTAssertEqual("certClient", transformed.certClient)
		XCTAssertEqual("certClientKey", transformed.certClientKey)
		XCTAssertEqual("certClientKeyPassword", transformed.certClientKeyPassword)
		XCTAssertEqual("clientID", transformed.clientID)
		XCTAssertEqual(4, transformed.limitTopic)
		XCTAssertEqual(5, transformed.limitMessagesBatch)
		XCTAssertEqual(HostAuthenticationType.certificate, transformed.auth)
	}
	
	func testTransformFromPersistenceModelAuthType() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let setting = HostSetting()
		setting.authType = AuthenticationType.NONE
		let transformed1 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.none, transformed1.auth)

		setting.authType = AuthenticationType.CERTIFICATE
		let transformed2 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.certificate, transformed2.auth)

		setting.authType = AuthenticationType.USERNAME_PASSWORD
		let transformed3 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.usernamePassword, transformed3.auth)
	}
	
	func testTransformToPersistenceModel() {
		let model = HostsModel(initMethod: self)
		
		let host = Host()
		host.alias = "alias"
		host.hostname = "hostname"
		host.port = 1
		host.topic = "topic"
		host.qos = 2
		host.auth = .certificate
		host.username = "username"
		host.password = "password"
		
		host.certServerCA = "certServerCA"
		host.certClient = "certClient"
		host.certClientKey = "certClientKey"
		host.certClientKeyPassword = "certClientKeyPassword"

		host.clientID = "clientID"

		host.limitTopic = 4
		host.limitMessagesBatch = 5
		
		let persistence = HostsModelPersistence(model: model)
		let transformed = persistence.transform(host)
		XCTAssertEqual("alias", transformed.alias)
		XCTAssertEqual("hostname", transformed.hostname)
		XCTAssertEqual(1, transformed.port)
		XCTAssertEqual("topic", transformed.topic)
		XCTAssertEqual(2, transformed.qos)
		XCTAssertEqual("username", transformed.username)
		XCTAssertEqual("password", transformed.password)
		XCTAssertEqual("certServerCA", transformed.certServerCA)
		XCTAssertEqual("certClient", transformed.certClient)
		XCTAssertEqual("certClientKey", transformed.certClientKey)
		XCTAssertEqual("certClientKeyPassword", transformed.certClientKeyPassword)
		XCTAssertEqual("clientID", transformed.clientID)
		XCTAssertEqual(4, transformed.limitTopic)
		XCTAssertEqual(5, transformed.limitMessagesBatch)
		XCTAssertEqual(AuthenticationType.CERTIFICATE, transformed.authType)
	}
	
	func testTransformToPersistenceModelAuthType() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let host = Host()
		host.auth = .none
		let transformed1 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.NONE, transformed1.authType)

		host.auth = .certificate
		let transformed2 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.CERTIFICATE, transformed2.authType)

		host.auth = .usernamePassword
		let transformed3 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.USERNAME_PASSWORD, transformed3.authType)
	}
}
