//
//  SubscribeCommand.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation
import ArgumentParser
import CocoaMQTT

struct SubscribeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscribe",
        abstract: "Subscribe to MQTT topics and stream messages",
        aliases: ["sub"]
    )

    @Option(name: [.short, .customLong("broker")], help: "Broker name to connect to")
    var broker: String?

    @Option(name: [.short, .customLong("file")], help: "Path to a .mqttbroker file")
    var file: String?

    @Argument(help: "Topic filter to subscribe to (default: broker's configured subscriptions)")
    var topic: String?

    @Option(help: "QoS level (0, 1, or 2)")
    var qos: Int?

    @Flag(name: [.short, .long], help: "Output messages as JSON with metadata")
    var json: Bool = false

    @Flag(name: [.short, .long], help: "Unwrap JSON payloads as nested objects (implies --json)")
    var unwrap: Bool = false

    func validate() throws {
        if broker == nil && file == nil {
            throw ValidationError("Either --broker or --file must be provided")
        }
        if let qos = qos {
            guard (0...2).contains(qos) else {
                throw ValidationError("QoS must be 0, 1, or 2")
            }
        }
    }

    func run() throws {
        let brokerInfo: BrokerInfo
        if let file = file {
            brokerInfo = try BrokerLoader.loadFromFile(path: file)
        } else {
            brokerInfo = try BrokerLoader.findBroker(name: broker!)
        }
        let handler = CLIMQTTHandler(broker: brokerInfo)

        let topics: [(String, Int)]
        if let topic = topic {
            topics = [(topic, qos ?? 0)]
        } else if !brokerInfo.subscriptions.isEmpty {
            topics = brokerInfo.subscriptions.map { ($0.topic, qos ?? $0.qos) }
        } else {
            topics = [("#", qos ?? 0)]
        }

        let outputJSON = json || unwrap
        handler.onMessage = { topic, payload, msgQos, retain in
            if outputJSON {
                var payloadValue: Any = payload
                if unwrap, let data = payload.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data) {
                    payloadValue = parsed
                }
                let jsonObj: [String: Any] = [
                    "topic": topic,
                    "payload": payloadValue,
                    "qos": msgQos,
                    "retain": retain,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
                if let data = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.withoutEscapingSlashes]),
                   let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
            } else {
                print("\(topic)\t\(payload)")
            }
            fflush(stdout)
        }

        handler.onError = { message in
            FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
        }

        handler.onDisconnect = { error in
            if let error = error {
                FileHandle.standardError.write(Data("Disconnected: \(error)\n".utf8))
            }
            Foundation.exit(1)
        }

        handler.onConnected = {
            for (t, q) in topics {
                FileHandle.standardError.write(Data("Subscribing to '\(t)' with QoS \(q)\n".utf8))
            }
            handler.subscribe(topics: topics)
        }

        setupSignalHandler {
            handler.disconnect()
            Foundation.exit(0)
        }

        handler.connect()

        dispatchMain()
    }
}
