//
//  SensSnycTest.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 20.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import CocoaMQTT
@testable import MQTTAnalyzer

private let host = "test.mqtt.rnd7.de"

class PublishSyncTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
	}
	
	func assertPublish(with broker: Host) throws {
		let topic = "integration/publish/\(String.random(length: 8))"
		
		try MQTTClientSync.publish(
			host: broker,
			topic: topic,
			message: "message",
			retain: false,
			qos: 1)
	}
	
	func testMQTT3() throws {
		let setting = BrokerSetting()
		setting.hostname = host

		let broker = Host(settings: setting)
		try assertPublish(with: broker)
	}

	func testMQTT5() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.protocolVersion = .mqtt5

		let broker = Host(settings: setting)
		try assertPublish(with: broker)
	}
	
	func testMQTTPersistedAuth() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 1884
		setting.authType = .usernamePassword
		setting.username = "admin"
		setting.password = "password"

		let broker = Host(settings: setting)
		try assertPublish(with: broker)
	}
	
	func testMQTTLetsEncryptTraefik() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 8883
		setting.ssl = true

		let broker = Host(settings: setting)
		try assertPublish(with: broker)
	}
	
	func testWebSocket() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 9001
		setting.protocolMethod = .websocket

		let broker = Host(settings: setting)
		try assertPublish(with: broker)
	}
	
	func testWebSocketMQTT5() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 9001
		setting.protocolMethod = .websocket
		setting.protocolVersion = .mqtt5

		let broker = Host(settings: setting)

		try assertPublish(with: broker)
	}
	
	func testWebSocketPersistedAuth() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 9002
		setting.protocolMethod = .websocket
		setting.authType = .usernamePassword
		setting.username = "admin"
		setting.password = "password"

		let broker = Host(settings: setting)

		try assertPublish(with: broker)
	}
	
	func testWebSocketLetsEncryptTraefik() throws {
		let setting = BrokerSetting()
		setting.hostname = host
		setting.port = 443
		setting.protocolMethod = .websocket
		setting.ssl = true

		let broker = Host(settings: setting)

		try assertPublish(with: broker)
	}
}
