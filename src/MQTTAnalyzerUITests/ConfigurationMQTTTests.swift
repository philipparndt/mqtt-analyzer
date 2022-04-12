//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import RealmSwift

class ConfigurationMQTTTests: AbstractConfigurationTests {
	func testMQTTNoAuth() {
		assertWithBroker(
			Broker(
				alias: "1883",
				hostname: hostname,
				port: 1883
			)
		)
	}
	
	func testMQTTPersistedAuth() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin",
				password: "password"
			)
		)
	}
	
	func testMQTTPersistedUsername() {
		assertWithBroker(
			Broker(
				alias: "1884",
				hostname: hostname,
				port: 1884,
				authType: .userPassword,
				username: "admin"
			),
			credentials: Credentials(username: nil, password: "password")
		)
	}
	
	func testMQTTLetsEncryptTraefik() {
		assertWithBroker(
			Broker(
				alias: "LE MQTTS",
				hostname: hostname,
				port: 8883,
				connectionProtocol: .mqtt,
				tls: true
			)
		)
	}
}
