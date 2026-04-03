//
//  PublishCommand.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import ArgumentParser
import CocoaMQTT

struct PublishCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "publish",
        abstract: "Publish a message to an MQTT topic",
        aliases: ["pub"]
    )

    @Option(name: [.short, .customLong("broker")], help: "Broker name to connect to")
    var broker: String?

    @Option(name: [.short, .customLong("file")], help: "Path to a .mqttbroker file")
    var file: String?

    @Argument(help: "Topic to publish to")
    var topic: String

    @Argument(help: "Message payload (use '-' to read from stdin)")
    var message: String

    @Option(help: "QoS level (0, 1, or 2)")
    var qos: Int = 0

    @Flag(help: "Set the retain flag")
    var retain: Bool = false

    func validate() throws {
        if broker == nil && file == nil {
            throw ValidationError("Either --broker or --file must be provided")
        }
        guard (0...2).contains(qos) else {
            throw ValidationError("QoS must be 0, 1, or 2")
        }
    }

    func run() throws {
        let brokerInfo: BrokerInfo
        if let file = file {
            brokerInfo = try BrokerLoader.loadFromFile(path: file)
        } else {
            brokerInfo = try BrokerLoader.findBroker(name: broker!)
        }

        var payload = message
        if message == "-" {
            let stdinData = FileHandle.standardInput.availableData
            guard let stdinStr = String(data: stdinData, encoding: .utf8) else {
                throw CLIMQTTError.stdinReadFailed
            }
            payload = stdinStr.trimmingCharacters(in: .newlines)
        }

        let handler = CLIMQTTHandler(broker: brokerInfo)
        var disconnecting = false

        handler.onError = { message in
            FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
            Foundation.exit(1)
        }

        handler.onDisconnect = { error in
            if disconnecting {
                Foundation.exit(0)
            }
            if let error = error {
                FileHandle.standardError.write(Data("Disconnected: \(error)\n".utf8))
            }
            Foundation.exit(1)
        }

        handler.onConnected = {
            handler.publish(topic: topic, message: payload, qos: qos, retain: retain)
        }

        handler.onPublished = {
            disconnecting = true
            handler.disconnect()
        }

        setupSignalHandler {
            handler.disconnect()
            Foundation.exit(1)
        }

        handler.connect()

        dispatchMain()
    }
}
