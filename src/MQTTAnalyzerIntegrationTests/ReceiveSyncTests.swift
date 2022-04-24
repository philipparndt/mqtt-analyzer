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

class ReceiveSyncTests: XCTestCase {
	private let topic = "integration/receive/\(String.random(length: 8))"
	private let message = String.random(length: 8)
	
	override func setUp() {
		super.setUp()

		let broker = Host()
		broker.hostname = host
		try? MQTTClientSync.publish(
			host: broker,
			topic: topic,
			message: message,
			retain: true,
			qos: 1)
	}
	
	func assertReceive(with broker: Host) throws {
		let message = try MQTTClientSync.receiveFirst(host: broker, topic: topic, timeout: 5)
		
		guard message != nil else {
			XCTAssertTrue(false, "Expected message")
			return
		}
		
		XCTAssertEqual(message, self.message)
	}

	func testMQTT3() throws {
		let broker = Host()
		broker.hostname = host
		try assertReceive(with: broker)
	}

	func testMQTT5() throws {
		let broker = Host()
		broker.hostname = host
		broker.protocolVersion = .mqtt5
		try assertReceive(with: broker)
	}
	
	func testMQTTPersistedAuth() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 1884
		broker.auth = .usernamePassword
		broker.username = "admin"
		broker.password = "password"
		try assertReceive(with: broker)
	}
	
	func testMQTTLetsEncryptTraefik() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 8883
		broker.ssl = true
		try assertReceive(with: broker)
	}
	
	func testWebSocket() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9001
		broker.protocolMethod = .websocket
		try assertReceive(with: broker)
	}
	
	func testWebSocketMQTT5() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9001
		broker.protocolMethod = .websocket
		broker.protocolVersion = .mqtt5
		try assertReceive(with: broker)
	}
	
	func testWebSocketPersistedAuth() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 9002
		broker.protocolMethod = .websocket
		broker.auth = .usernamePassword
		broker.username = "admin"
		broker.password = "password"
		try assertReceive(with: broker)
	}
	
	func testWebSocketLetsEncryptTraefik() throws {
		let broker = Host()
		broker.hostname = host
		broker.port = 443
		broker.protocolMethod = .websocket
		broker.ssl = true
		try assertReceive(with: broker)
	}
}
