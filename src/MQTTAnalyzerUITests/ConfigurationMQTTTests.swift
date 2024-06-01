//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class ConfigurationMQTTTests: AbstractConfigurationTests {
	@MainActor func testMQTTNoAuth() {
		assertWithBroker(
			Broker(
				alias: "1883",
				hostname: hostname,
				port: 1883
			),
			tc: self
		)
	}
	
	@MainActor func testMQTT5NoAuth() {
		assertWithBroker(
			Broker(
				alias: "MQTT 5",
				hostname: hostname,
				port: 1883,
				protocolVersion: .mqtt5
			),
			tc: self
		)
	}
	
	@MainActor func testMQTTPersistedAuth() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin",
				password: "password"
			),
			tc: self
		)
	}
	
	@MainActor func testMQTTPersistedUsername() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin"
			),
			tc: self,
			credentials: Credentials(username: nil, password: "password")
		)
	}
	
	@MainActor func testMQTTLetsEncryptTraefik() {
		assertWithBroker(
			Broker(
				alias: "LE MQTTS",
				hostname: hostname,
				port: 8883,
				connectionProtocol: .mqtt,
				tls: true
			),
			tc: self
		)
	}
}
