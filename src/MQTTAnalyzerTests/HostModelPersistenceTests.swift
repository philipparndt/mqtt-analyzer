//
//  HostModelPersistenceTests.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2020-02-28.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest
import CoreData
@testable import MQTTAnalyzer

class HostModelPersistenceTests: XCTestCase, InitHost {
	func initHost(host: Host) {
		// Empty by intention
	}
	
	func testEncodeDecodeSubscriptions() {
		let subscriptions: [TopicSubscription] = [
			TopicSubscription(topic: "#", qos: 0),
			TopicSubscription(topic: "$SYS/#", qos: 1)
		]
		let data = HostsModelPersistence.encode(subscriptions: subscriptions)
		let decoded = HostsModelPersistence.decode(subscriptions: data)
		XCTAssertEqual(2, decoded.count)
		XCTAssertEqual("#", decoded[0].topic)
		XCTAssertEqual(0, decoded[0].qos)
		XCTAssertEqual("$SYS/#", decoded[1].topic)
		XCTAssertEqual(1, decoded[1].qos)
	}
	
	func testTransformFromPersistenceModel() {
		let model = HostsModel(initMethod: self)
		
		let setting = HostSetting()
		setting.alias = "alias"
		setting.hostname = "hostname"
		setting.port = 1
		setting.subscriptions = HostsModelPersistence.encode(subscriptions: [
			TopicSubscription(topic: "topic", qos: 2)
		])
		setting.authType = AuthenticationType.certificate
		setting.username = "username"
		setting.password = "password"
		setting.certificates = HostsModelPersistence.encode(certificates: [
			CertificateFile(name: "certServerCA", location: .local, type: .serverCA),
			CertificateFile(name: "certClient", location: .local, type: .client),
			CertificateFile(name: "certClientKey", location: .local, type: .clientKey)
		])
		setting.certClientKeyPassword = "certClientKeyPassword"

		setting.clientID = "clientID"

		setting.limitTopic = 4
		setting.limitMessagesBatch = 5
		
		let persistence = HostsModelPersistence(model: model)
		let transformed = persistence.transform(setting)
		XCTAssertEqual("alias", transformed.alias)
		XCTAssertEqual("hostname", transformed.hostname)
		XCTAssertEqual(1, transformed.port)
		XCTAssertEqual(1, transformed.subscriptions.count)
		XCTAssertEqual("topic", transformed.subscriptions[0].topic)
		XCTAssertEqual(2, transformed.subscriptions[0].qos)
		XCTAssertEqual("username", transformed.username)
		XCTAssertEqual("password", transformed.password)
		XCTAssertEqual("certServerCA", getCertificate(transformed, type: .serverCA)!.name)
		XCTAssertEqual("certClient", getCertificate(transformed, type: .client)!.name)
		XCTAssertEqual("certClientKey", getCertificate(transformed, type: .clientKey)!.name)
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
		setting.authType = AuthenticationType.none
		let transformed1 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.none, transformed1.auth)

		setting.authType = AuthenticationType.certificate
		let transformed2 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.certificate, transformed2.auth)

		setting.authType = AuthenticationType.usernamePassword
		let transformed3 = persistence.transform(setting)
		XCTAssertEqual(HostAuthenticationType.usernamePassword, transformed3.auth)
	}
	
	func testTransformFromPersistenceModelClientImplType() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let setting = HostSetting()
		setting.clientImplType = ClientImplType.cocoamqtt
		let transformed1 = persistence.transform(setting)
		XCTAssertEqual(HostClientImplType.cocoamqtt, transformed1.clientImpl)

		setting.clientImplType = ClientImplType.moscapsule
		let transformed2 = persistence.transform(setting)
		XCTAssertEqual(HostClientImplType.moscapsule, transformed2.clientImpl)
	}
	
	func testTransformFromPersistenceModelSSL() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let setting = HostSetting()
		setting.ssl = false
		let transformed1 = persistence.transform(setting)
		XCTAssertFalse(transformed1.ssl)

		setting.ssl = true
		let transformed2 = persistence.transform(setting)
		XCTAssertTrue(transformed2.ssl)
	}
	
	func testTransformFromPersistenceModelSSLUntrusted() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let setting = HostSetting()
		setting.untrustedSSL = false
		let transformed1 = persistence.transform(setting)
		XCTAssertFalse(transformed1.untrustedSSL)

		setting.untrustedSSL = true
		let transformed2 = persistence.transform(setting)
		XCTAssertTrue(transformed2.untrustedSSL)
	}
	
	func testTransformToPersistenceModel() {
		let model = HostsModel(initMethod: self)
		
		let host = Host()
		host.alias = "alias"
		host.hostname = "hostname"
		host.port = 1
		host.subscriptions = [
			TopicSubscription(topic: "topic", qos: 2)
		]
		host.auth = .certificate
		host.username = "username"
		host.password = "password"
		
		host.certificates = [
			CertificateFile(name: "certServerCA", location: .local, type: .serverCA),
			CertificateFile(name: "certClient", location: .local, type: .client),
			CertificateFile(name: "certClientKey", location: .local, type: .clientKey)
		]
		host.certClientKeyPassword = "certClientKeyPassword"

		host.clientID = "clientID"

		host.limitTopic = 4
		host.limitMessagesBatch = 5
		
		let persistence = HostsModelPersistence(model: model)
		let transformed = persistence.transform(host)
		XCTAssertEqual("alias", transformed.alias)
		XCTAssertEqual("hostname", transformed.hostname)
		XCTAssertEqual(1, transformed.port)
		XCTAssertEqual("""
		[{"topic":"topic","qos":2}]
		""", String(decoding: transformed.subscriptions, as: UTF8.self))
		XCTAssertEqual("username", transformed.username)
		XCTAssertEqual("password", transformed.password)
		
		let expectedCerts =
			 	"""
				[{"name":"certServerCA","location":1,"type":1},
				"""
			+ 	"""
				{"name":"certClient","location":1,"type":2},
				"""
			+ 	"""
				{"name":"certClientKey","location":1,"type":3}]
				"""
		
		XCTAssertEqual(expectedCerts, String(decoding: transformed.certificates, as: UTF8.self))
		XCTAssertEqual("certClientKeyPassword", transformed.certClientKeyPassword)
		XCTAssertEqual("clientID", transformed.clientID)
		XCTAssertEqual(4, transformed.limitTopic)
		XCTAssertEqual(5, transformed.limitMessagesBatch)
		XCTAssertEqual(AuthenticationType.certificate, transformed.authType)
	}
	
	func testTransformToPersistenceModelAuthType() {
		let model = HostsModel(initMethod: self)
		
		let persistence = HostsModelPersistence(model: model)

		let host = Host()
		host.auth = .none
		let transformed1 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.none, transformed1.authType)

		host.auth = .certificate
		let transformed2 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.certificate, transformed2.authType)

		host.auth = .usernamePassword
		let transformed3 = persistence.transform(host)
		XCTAssertEqual(AuthenticationType.usernamePassword, transformed3.authType)
	}
	
	func testTransformToPersistenceModelClientImplType() {
		let model = HostsModel(initMethod: self)
		let persistence = HostsModelPersistence(model: model)

		let host = Host()
		host.clientImpl = .cocoamqtt
		let transformed1 = persistence.transform(host)
		XCTAssertEqual(ClientImplType.cocoamqtt, transformed1.clientImplType)

		host.clientImpl = .moscapsule
		let transformed2 = persistence.transform(host)
		XCTAssertEqual(ClientImplType.moscapsule, transformed2.clientImplType)
	}
	
	func testTransformToPersistenceModelSSL() {
		let model = HostsModel(initMethod: self)
		let persistence = HostsModelPersistence(model: model)

		let host = Host()
		host.ssl = false
		let transformed1 = persistence.transform(host)
		XCTAssertFalse(transformed1.ssl)

		host.ssl = true
		let transformed2 = persistence.transform(host)
		XCTAssertTrue(transformed2.ssl)
	}
	
	func testTransformToPersistenceModelSSLUntrusted() {
		let model = HostsModel(initMethod: self)
		let persistence = HostsModelPersistence(model: model)

		let host = Host()
		host.untrustedSSL = false
		let transformed1 = persistence.transform(host)
		XCTAssertFalse(transformed1.untrustedSSL)

		host.untrustedSSL = true
		let transformed2 = persistence.transform(host)
		XCTAssertTrue(transformed2.untrustedSSL)
	}
}
