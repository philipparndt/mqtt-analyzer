//
//  CLIArgumentParsingTests.swift
//  MQTTAnalyzerCLITests
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import XCTest
import ArgumentParser

final class CLIArgumentParsingTests: XCTestCase {

    func testRootCommandHelp() throws {
        XCTAssertNoThrow(try MQTTAnalyzerCommand.parseAsRoot(["--help"]))
    }

    func testListCommandParsing() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot(["list"])
        XCTAssertTrue(command is ListCommand)
    }

    func testSubscribeCommandParsing() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot(["subscribe", "-b", "MyBroker", "home/#"])
        guard let subscribe = command as? SubscribeCommand else {
            XCTFail("Expected SubscribeCommand")
            return
        }
        XCTAssertEqual(subscribe.broker, "MyBroker")
        XCTAssertEqual(subscribe.topic, "home/#")
        XCTAssertNil(subscribe.qos)
        XCTAssertFalse(subscribe.json)
    }

    func testSubscribeCommandWithOptions() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot([
            "subscribe", "-b", "Broker", "test/topic", "--qos", "2", "--json"
        ])
        guard let subscribe = command as? SubscribeCommand else {
            XCTFail("Expected SubscribeCommand")
            return
        }
        XCTAssertEqual(subscribe.broker, "Broker")
        XCTAssertEqual(subscribe.topic, "test/topic")
        XCTAssertEqual(subscribe.qos, 2)
        XCTAssertTrue(subscribe.json)
    }

    func testSubscribeCommandWithoutTopic() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot(["subscribe", "-b", "Broker"])
        guard let subscribe = command as? SubscribeCommand else {
            XCTFail("Expected SubscribeCommand")
            return
        }
        XCTAssertEqual(subscribe.broker, "Broker")
        XCTAssertNil(subscribe.topic)
    }

    func testSubscribeCommandInvalidQoS() {
        XCTAssertThrowsError(try MQTTAnalyzerCommand.parseAsRoot([
            "subscribe", "-b", "Broker", "topic", "--qos", "5"
        ]))
    }

    func testPublishCommandParsing() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot([
            "publish", "-b", "MyBroker", "home/light", "on"
        ])
        guard let publish = command as? PublishCommand else {
            XCTFail("Expected PublishCommand")
            return
        }
        XCTAssertEqual(publish.broker, "MyBroker")
        XCTAssertEqual(publish.topic, "home/light")
        XCTAssertEqual(publish.message, "on")
        XCTAssertEqual(publish.qos, 0)
        XCTAssertFalse(publish.retain)
    }

    func testPublishCommandWithOptions() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot([
            "publish", "-b", "Broker", "topic", "payload", "--qos", "1", "--retain"
        ])
        guard let publish = command as? PublishCommand else {
            XCTFail("Expected PublishCommand")
            return
        }
        XCTAssertEqual(publish.qos, 1)
        XCTAssertTrue(publish.retain)
    }

    func testPublishCommandStdinFlag() throws {
        let command = try MQTTAnalyzerCommand.parseAsRoot([
            "publish", "-b", "Broker", "topic", "-"
        ])
        guard let publish = command as? PublishCommand else {
            XCTFail("Expected PublishCommand")
            return
        }
        XCTAssertEqual(publish.message, "-")
    }

    func testSubscribeCommandMissingBroker() {
        XCTAssertThrowsError(try MQTTAnalyzerCommand.parseAsRoot(["subscribe"]))
    }

    func testPublishCommandMissingArguments() {
        XCTAssertThrowsError(try MQTTAnalyzerCommand.parseAsRoot(["publish", "-b", "Broker"]))
    }
}
