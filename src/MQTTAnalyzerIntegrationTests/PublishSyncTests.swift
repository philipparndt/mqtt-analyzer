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
		let broker = Host()
		broker.hostname = host
		try assertPublish(with: broker)
	}

	func testMQTT5() throws {
		let broker = Host()
		broker.hostname = host
		broker.protocolVersion = .mqtt5
		try assertPublish(with: broker)
	}
	
	func testMQTTPersistedAuth() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 1884
		broker.auth = .usernamePassword
		broker.username = "admin"
		broker.password = "password"
		try assertPublish(with: broker)
	}
	
	func testMQTTLetsEncryptTraefik() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 8883
		broker.ssl = true
		try assertPublish(with: broker)
	}
	
	func testWebSocket() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9001
		broker.protocolMethod = .websocket
		try assertPublish(with: broker)
	}
	
	func testWebSocketMQTT5() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9001
		broker.protocolMethod = .websocket
		broker.protocolVersion = .mqtt5
		try assertPublish(with: broker)
	}
	
	func testWebSocketPersistedAuth() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9002
		broker.protocolMethod = .websocket
		broker.auth = .usernamePassword
		broker.username = "admin"
		broker.password = "password"
		try assertPublish(with: broker)
	}
	
	func testWebSocketLetsEncryptTraefik() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 443
		broker.protocolMethod = .websocket
		broker.ssl = true
		try assertPublish(with: broker)
	}
}
