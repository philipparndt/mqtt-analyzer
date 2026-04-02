//
//  BrokerLoaderTests.swift
//  MQTTAnalyzerCLITests
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import XCTest

final class BrokerLoaderTests: XCTestCase {

    func testBrokerInfoCreation() {
        let broker = BrokerInfo(
            alias: "Test Broker",
            hostname: "mqtt.example.com",
            port: 1883,
            ssl: false,
            untrustedSSL: false,
            alpn: nil,
            authType: .none,
            username: nil,
            password: nil,
            clientID: nil,
            protocolVersion: .mqtt3,
            protocolMethod: .mqtt,
            basePath: nil,
            subscriptions: []
        )

        XCTAssertEqual(broker.alias, "Test Broker")
        XCTAssertEqual(broker.hostname, "mqtt.example.com")
        XCTAssertEqual(broker.port, 1883)
        XCTAssertFalse(broker.ssl)
        XCTAssertEqual(broker.protocolVersion, .mqtt3)
        XCTAssertEqual(broker.protocolMethod, .mqtt)
    }

    func testBrokerInfoWithSSL() {
        let broker = BrokerInfo(
            alias: "Secure Broker",
            hostname: "mqtt.example.com",
            port: 8883,
            ssl: true,
            untrustedSSL: true,
            alpn: "mqtt",
            authType: .usernamePassword,
            username: "user",
            password: "pass",
            clientID: "test-client",
            protocolVersion: .mqtt5,
            protocolMethod: .websocket,
            basePath: "/mqtt",
            subscriptions: [CLITopicSubscription(topic: "#", qos: 0)]
        )

        XCTAssertEqual(broker.alias, "Secure Broker")
        XCTAssertEqual(broker.port, 8883)
        XCTAssertTrue(broker.ssl)
        XCTAssertTrue(broker.untrustedSSL)
        XCTAssertEqual(broker.alpn, "mqtt")
        XCTAssertEqual(broker.authType, .usernamePassword)
        XCTAssertEqual(broker.username, "user")
        XCTAssertEqual(broker.password, "pass")
        XCTAssertEqual(broker.clientID, "test-client")
        XCTAssertEqual(broker.protocolVersion, .mqtt5)
        XCTAssertEqual(broker.protocolMethod, .websocket)
        XCTAssertEqual(broker.basePath, "/mqtt")
        XCTAssertEqual(broker.subscriptions.count, 1)
        XCTAssertEqual(broker.subscriptions[0].topic, "#")
    }

    func testCLIProtocolVersionRawValues() {
        XCTAssertEqual(CLIProtocolVersion.mqtt3.rawValue, 0)
        XCTAssertEqual(CLIProtocolVersion.mqtt5.rawValue, 1)
    }

    func testCLIProtocolMethodRawValues() {
        XCTAssertEqual(CLIProtocolMethod.mqtt.rawValue, 0)
        XCTAssertEqual(CLIProtocolMethod.websocket.rawValue, 1)
    }

    func testCLIAuthTypeRawValues() {
        XCTAssertEqual(CLIAuthType.none.rawValue, 0)
        XCTAssertEqual(CLIAuthType.usernamePassword.rawValue, 1)
        XCTAssertEqual(CLIAuthType.certificate.rawValue, 2)
        XCTAssertEqual(CLIAuthType.both.rawValue, 3)
    }

    func testBrokerLoaderErrorDescriptions() {
        let storeNotFound = BrokerLoaderError.storeNotFound
        XCTAssertTrue(storeNotFound.description.contains("CoreData store not found"))

        let modelNotFound = BrokerLoaderError.modelNotFound("test detail")
        XCTAssertTrue(modelNotFound.description.contains("CoreData model not found"))
        XCTAssertTrue(modelNotFound.description.contains("test detail"))

        let notFound = BrokerLoaderError.brokerNotFound("Test", available: ["A", "B"])
        XCTAssertTrue(notFound.description.contains("Test"))
        XCTAssertTrue(notFound.description.contains("A, B"))

        let noBrokers = BrokerLoaderError.noBrokersConfigured
        XCTAssertTrue(noBrokers.description.contains("No brokers configured"))
    }

    func testTopicSubscriptionDecoding() throws {
        let json = """
        [{"topic": "home/#", "qos": 1}, {"topic": "test/+", "qos": 0}]
        """
        let data = json.data(using: .utf8)!
        let subs = try JSONDecoder().decode([CLITopicSubscription].self, from: data)

        XCTAssertEqual(subs.count, 2)
        XCTAssertEqual(subs[0].topic, "home/#")
        XCTAssertEqual(subs[0].qos, 1)
        XCTAssertEqual(subs[1].topic, "test/+")
        XCTAssertEqual(subs[1].qos, 0)
    }
}
