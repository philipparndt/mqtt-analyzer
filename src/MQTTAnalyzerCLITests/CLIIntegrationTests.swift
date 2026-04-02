//
//  CLIIntegrationTests.swift
//  MQTTAnalyzerCLITests
//
//  Integration tests that use the test broker at test.mqtt.rnd7.de
//

import XCTest
import Foundation
import CocoaMQTT

private let testHost = "test.mqtt.rnd7.de"
private let testPort: UInt16 = 1883

final class CLIIntegrationTests: XCTestCase {

    private var brokerFilePath: String!

    override func setUp() {
        super.setUp()
        // Create a temporary .mqttbroker file for the test broker
        let brokerJSON: [String: Any] = [
            "version": 1,
            "broker": [
                "alias": "Test Broker",
                "hostname": testHost,
                "port": Int(testPort),
                "protocolMethod": "mqtt",
                "protocolVersion": "mqtt3",
                "basePath": "",
                "ssl": false,
                "untrustedSSL": false,
                "authType": "none",
                "subscriptions": [["topic": "#", "qos": 0]],
                "limitTopic": 0,
                "limitMessagesBatch": 500
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: brokerJSON, options: .prettyPrinted)
        brokerFilePath = NSTemporaryDirectory() + "cli-test-\(UUID().uuidString).mqttbroker"
        FileManager.default.createFile(atPath: brokerFilePath, contents: data)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: brokerFilePath)
        super.tearDown()
    }

    // MARK: - Subscribe: verify message output format

    func testSubscribeReceivesRetainedMessage() throws {
        let topic = "cli-integration/sub/\(randomID())"
        let payload = "hello-\(randomID())"

        try publishMessage(topic: topic, payload: payload, retain: true, qos: .qos1)

        let output = try runCLIWithTimeout(
            args: ["subscribe", "-f", brokerFilePath, topic],
            timeout: 10
        )

        XCTAssertTrue(output.contains(topic), "Output should contain topic: \(output)")
        XCTAssertTrue(output.contains(payload), "Output should contain payload: \(output)")

        // Clean up retained message
        try publishMessage(topic: topic, payload: "", retain: true, qos: .qos1)
    }

    func testSubscribeJSONFormat() throws {
        let topic = "cli-integration/json/\(randomID())"
        let payload = "test-json-\(randomID())"

        try publishMessage(topic: topic, payload: payload, retain: true, qos: .qos1)

        let output = try runCLIWithTimeout(
            args: ["subscribe", "-f", brokerFilePath, "-j", topic],
            timeout: 10
        )

        guard let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: "\n").first,
              let data = String(line).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Output is not valid JSON: \(output)")
            return
        }

        XCTAssertEqual(json["topic"] as? String, topic)
        XCTAssertEqual(json["payload"] as? String, payload)
        XCTAssertNotNil(json["qos"])
        XCTAssertNotNil(json["retain"])
        XCTAssertNotNil(json["timestamp"])

        try publishMessage(topic: topic, payload: "", retain: true, qos: .qos1)
    }

    // MARK: - Publish: verify delivery

    func testPublishAndReceive() throws {
        let topic = "cli-integration/pub/\(randomID())"
        let payload = "pub-test-\(randomID())"

        let received = expectMessage(on: topic, timeout: 10)

        // Small delay to ensure subscriber is connected
        Thread.sleep(forTimeInterval: 1)

        // Publish via CLI
        _ = try runCLIWithTimeout(
            args: ["publish", "-f", brokerFilePath, topic, payload],
            timeout: 10
        )

        let message = try received()
        XCTAssertEqual(message, payload)
    }

    // MARK: - Helpers

    private func randomID() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<8).map { _ in letters.randomElement()! })
    }

    private func cliBinaryPath() -> String {
        let testBundle = Bundle(for: type(of: self))
        let productsDir = testBundle.bundleURL.deletingLastPathComponent()
        return productsDir.appendingPathComponent("mqtt-analyzer").path
    }

    private func runCLIWithTimeout(args: [String], timeout: TimeInterval) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliBinaryPath())
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if process.isRunning { process.terminate() }
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(data: data, encoding: .utf8) ?? ""
    }

    private func publishMessage(topic: String, payload: String, retain: Bool, qos: CocoaMQTTQoS) throws {
        let mqtt = CocoaMQTT(clientID: "cli-test-pub-\(randomID())", host: testHost, port: testPort)
        mqtt.autoReconnect = false

        let connected = DispatchSemaphore(value: 0)
        let published = DispatchSemaphore(value: 0)

        mqtt.didConnectAck = { _, ack in
            if ack == .accept { connected.signal() }
        }
        mqtt.didPublishMessage = { _, _, _ in
            published.signal()
        }

        guard mqtt.connect() else { throw TestError.connectionFailed }
        guard connected.wait(timeout: .now() + 5) == .success else { throw TestError.connectionTimeout }

        mqtt.publish(CocoaMQTTMessage(topic: topic, string: payload, qos: qos, retained: retain))

        guard published.wait(timeout: .now() + 5) == .success else {
            mqtt.disconnect()
            throw TestError.publishTimeout
        }
        mqtt.disconnect()
    }

    private func expectMessage(on topic: String, timeout: TimeInterval) -> () throws -> String {
        let mqtt = CocoaMQTT(clientID: "cli-test-sub-\(randomID())", host: testHost, port: testPort)
        mqtt.autoReconnect = false

        let semaphore = DispatchSemaphore(value: 0)
        var receivedMessage: String?

        mqtt.didConnectAck = { mqtt, ack in
            if ack == .accept { mqtt.subscribe(topic, qos: .qos1) }
        }
        mqtt.didReceiveMessage = { _, message, _ in
            receivedMessage = message.string
            semaphore.signal()
        }

        guard mqtt.connect() else {
            return { throw TestError.connectionFailed }
        }

        return {
            guard semaphore.wait(timeout: .now() + timeout) == .success else {
                mqtt.disconnect()
                throw TestError.receiveTimeout
            }
            mqtt.disconnect()
            return receivedMessage ?? ""
        }
    }
}

private enum TestError: Error {
    case connectionFailed
    case connectionTimeout
    case publishTimeout
    case receiveTimeout
}
