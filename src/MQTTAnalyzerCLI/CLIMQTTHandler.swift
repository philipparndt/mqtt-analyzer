//
//  CLIMQTTHandler.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT
import CocoaMQTTWebSocket
import Network

enum CLIMQTTError: Error, CustomStringConvertible {
    case connectionFailed(String)
    case authenticationFailed(String)
    case stdinReadFailed

    var description: String {
        switch self {
        case .connectionFailed(let msg):
            return "Connection failed: \(msg)"
        case .authenticationFailed(let msg):
            return "Authentication failed: \(msg)"
        case .stdinReadFailed:
            return "Failed to read from stdin"
        }
    }
}

class CLIMQTTHandler: NSObject {
    let broker: BrokerInfo
    private var mqtt3: CocoaMQTT?
    private var mqtt5: CocoaMQTT5?

    var onMessage: ((_ topic: String, _ payload: String, _ qos: Int, _ retain: Bool) -> Void)?
    var onError: ((_ message: String) -> Void)?
    var onDisconnect: ((_ error: String?) -> Void)?
    var onConnected: (() -> Void)?
    var onPublished: (() -> Void)?

    init(broker: BrokerInfo) {
        self.broker = broker
        super.init()
    }

    func connect() {
        let clientID = broker.clientID?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? broker.clientID!
            : "mqtt-analyzer-cli-\(randomString(length: 8))"

        if broker.protocolVersion == .mqtt5 {
            connectMQTT5(clientID: clientID)
        } else {
            connectMQTT3(clientID: clientID)
        }
    }

    func disconnect() {
        mqtt3?.disconnect()
        mqtt5?.disconnect()
    }

    func subscribe(topics: [(String, Int)]) {
        for (topic, qos) in topics {
            let cocoaQos = convertQoS(qos)
            if broker.protocolVersion == .mqtt5 {
                mqtt5?.subscribe(topic, qos: cocoaQos)
            } else {
                mqtt3?.subscribe(topic, qos: cocoaQos)
            }
        }
    }

    func publish(topic: String, message: String, qos: Int, retain: Bool) {
        let cocoaQos = convertQoS(qos)
        if broker.protocolVersion == .mqtt5 {
            let msg = CocoaMQTT5Message(topic: topic, string: message, qos: cocoaQos, retained: retain)
            mqtt5?.publish(msg, properties: MqttPublishProperties())
        } else {
            let msg = CocoaMQTTMessage(topic: topic, string: message, qos: cocoaQos, retained: retain)
            mqtt3?.publish(msg)
        }
    }

    // MARK: - Private

    private func connectMQTT3(clientID: String) {
        let client: CocoaMQTT
        if broker.protocolMethod == .websocket {
            let websocket = CocoaMQTTWebSocket(uri: broker.basePath ?? "/mqtt")
            client = CocoaMQTT(clientID: clientID, host: broker.hostname, port: UInt16(broker.port), socket: websocket)
        } else {
            client = CocoaMQTT(clientID: clientID, host: broker.hostname, port: UInt16(broker.port))
        }

        configureCommon(client: client)
        client.didReceiveMessage = { [weak self] _, message, _ in
            let payload = message.string ?? "[\(message.payload.count) bytes]"
            self?.onMessage?(message.topic, payload, Int(message.qos.rawValue), message.retained)
        }
        client.didConnectAck = { [weak self] _, ack in
            if ack == .accept {
                self?.onConnected?()
            } else {
                self?.onError?("Connection rejected: \(ack)")
            }
        }
        client.didPublishMessage = { [weak self] _, _, _ in
            self?.onPublished?()
        }
        client.didDisconnect = { [weak self] _, error in
            self?.onDisconnect?(error?.localizedDescription)
        }

        mqtt3 = client
        if !client.connect() {
            onError?("Failed to initiate connection to \(broker.hostname):\(broker.port)")
        }
    }

    private func connectMQTT5(clientID: String) {
        let client: CocoaMQTT5
        if broker.protocolMethod == .websocket {
            let websocket = CocoaMQTTWebSocket(uri: broker.basePath ?? "/mqtt")
            client = CocoaMQTT5(clientID: clientID, host: broker.hostname, port: UInt16(broker.port), socket: websocket)
        } else {
            client = CocoaMQTT5(clientID: clientID, host: broker.hostname, port: UInt16(broker.port))
        }

        configureCommon5(client: client)
        client.didReceiveMessage = { [weak self] _, message, _, _ in
            let payload = message.string ?? "[\(message.payload.count) bytes]"
            self?.onMessage?(message.topic, payload, Int(message.qos.rawValue), message.retained)
        }
        client.didConnectAck = { [weak self] _, ack, _ in
            if ack == .success {
                self?.onConnected?()
            } else {
                self?.onError?("Connection rejected: \(ack)")
            }
        }
        client.didPublishMessage = { [weak self] _, _, _ in
            self?.onPublished?()
        }
        client.didDisconnect = { [weak self] _, error in
            self?.onDisconnect?(error?.localizedDescription)
        }

        mqtt5 = client
        if !client.connect() {
            onError?("Failed to initiate connection to \(broker.hostname):\(broker.port)")
        }
    }

    private func configureCommon(client: CocoaMQTT) {
        client.enableSSL = broker.ssl
        client.allowUntrustCACertificate = broker.untrustedSSL

        if let alpn = broker.alpn, !alpn.isEmpty {
            client.alpnProtocols = [alpn]
        }

        if broker.authType == .usernamePassword || broker.authType == .both {
            client.username = broker.username
            client.password = broker.password
        }

        client.keepAlive = 60
        client.autoReconnect = false
    }

    private func configureCommon5(client: CocoaMQTT5) {
        client.enableSSL = broker.ssl
        client.allowUntrustCACertificate = broker.untrustedSSL

        if let alpn = broker.alpn, !alpn.isEmpty {
            client.alpnProtocols = [alpn]
        }

        if broker.authType == .usernamePassword || broker.authType == .both {
            client.username = broker.username
            client.password = broker.password
        }

        client.keepAlive = 60
        client.autoReconnect = false
    }

    private func convertQoS(_ qos: Int) -> CocoaMQTTQoS {
        switch qos {
        case 1: return .qos1
        case 2: return .qos2
        default: return .qos0
        }
    }
}

private func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}
