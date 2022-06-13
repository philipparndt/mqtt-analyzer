//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class ConfigurationWebSocketTests: AbstractConfigurationTests {
	func testWebSocketLetsEncryptTraefik() {
		assertWithBroker(
			Broker(
				alias: "LE WSS",
				hostname: hostname,
				port: 443,
				connectionProtocol: .websocket,
				tls: true
			)
		)
	}
	
	func testMQTT5NoAuth() {
		assertWithBroker(
			Broker(
				alias: "WS MQTT 5",
				hostname: hostname,
				port: 9001,
				connectionProtocol: .websocket,
				protocolVersion: .mqtt5
			)
		)
	}
	
	func testWebSocket() {
		assertWithBroker(
			Broker(
				alias: "WebSocket",
				hostname: hostname,
				port: 9001,
				connectionProtocol: .websocket
			)
		)
	}
	
	func testWebSocketPersistedAuth() {
		assertWithBroker(
			Broker(
				alias: "9002",
				hostname: hostname,
				port: 9002,
				connectionProtocol: .websocket,
				authType: .userPassword,
				username: "admin",
				password: "password"
			)
		)
	}
	
	func testWebSocketPersistedUsername() {
		assertWithBroker(
			Broker(
				alias: "9002",
				hostname: hostname,
				port: 9002,
				connectionProtocol: .websocket,
				authType: .userPassword,
				username: "admin"
			),
			credentials: Credentials(username: nil, password: "password")
		)
	}
}
