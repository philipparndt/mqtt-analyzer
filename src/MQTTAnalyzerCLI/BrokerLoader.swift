//
//  BrokerLoader.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import CoreData

enum CLIProtocolVersion: Int32 {
    case mqtt3 = 0
    case mqtt5 = 1
}

enum CLIProtocolMethod: Int32 {
    case mqtt = 0
    case websocket = 1
}

enum CLIAuthType: Int32 {
    case none = 0
    case usernamePassword = 1
    case certificate = 2
    case both = 3
}

typealias CLITopicSubscription = TopicSubscription

// MARK: - .mqttbroker file format

struct BrokerFileDocument: Codable {
    let version: Int
    let broker: BrokerFileModel
}

struct BrokerFileModel: Codable {
    let alias: String
    let hostname: String
    let port: Int
    let protocolMethod: String
    let protocolVersion: String
    let basePath: String?
    let ssl: Bool
    let untrustedSSL: Bool
    let alpn: String?
    let authType: String
    let username: String?
    let password: String?
    let clientID: String?
    let subscriptions: [BrokerFileSubscription]
}

struct BrokerFileSubscription: Codable {
    let topic: String
    let qos: Int
}

// MARK: - BrokerInfo

struct BrokerInfo {
    let alias: String
    let hostname: String
    let port: Int32
    let ssl: Bool
    let untrustedSSL: Bool
    let alpn: String?
    let authType: CLIAuthType
    let username: String?
    let password: String?
    let clientID: String?
    let protocolVersion: CLIProtocolVersion
    let protocolMethod: CLIProtocolMethod
    let basePath: String?
    let subscriptions: [CLITopicSubscription]
}

enum BrokerLoaderError: Error, CustomStringConvertible {
    case storeNotFound
    case modelNotFound(String)
    case loadFailed(String)
    case brokerFileFailed(String)
    case brokerNotFound(String, available: [String])
    case noBrokersConfigured

    var description: String {
        switch self {
        case .storeNotFound:
            return "CoreData store not found. Is MQTT Analyzer installed?"
        case .modelNotFound(let detail):
            return "CoreData model not found. \(detail)"
        case .brokerFileFailed(let reason):
            return "Failed to load broker file: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load brokers: \(reason)"
        case .brokerNotFound(let name, let available):
            let list = available.isEmpty ? "(none)" : available.joined(separator: ", ")
            return "Broker '\(name)' not found. Available: \(list)"
        case .noBrokersConfigured:
            return "No brokers configured. Use the MQTT Analyzer app to add brokers."
        }
    }
}

class BrokerLoader {
    static func resolveStorePath() -> URL? {
        // App Group container (used by the macOS app)
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer") {
            let storeURL = groupURL.appendingPathComponent("data")
            if FileManager.default.fileExists(atPath: storeURL.path) {
                return storeURL
            }
        }

        // Sandboxed container
        let sandboxPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/de.rnd7.MQTTAnalyzer/Data/Library/Application Support/data")
        if FileManager.default.fileExists(atPath: sandboxPath.path) {
            return sandboxPath
        }

        // Non-sandboxed Application Support
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportPath = appSupport.appendingPathComponent("de.rnd7.MQTTAnalyzer/data")
            if FileManager.default.fileExists(atPath: appSupportPath.path) {
                return appSupportPath
            }
        }

        return nil
    }

    static func loadAllBrokers() throws -> [BrokerInfo] {
        guard let storeURL = resolveStorePath() else {
            throw BrokerLoaderError.storeNotFound
        }

        guard let modelURL = findModelURL() else {
            throw BrokerLoaderError.modelNotFound("Searched from: \(resolveExecutableDirectory().path)")
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw BrokerLoaderError.modelNotFound("Found at \(modelURL.path) but failed to load")
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options: [String: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSReadOnlyPersistentStoreOption: true
        ]

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            throw BrokerLoaderError.loadFailed(error.localizedDescription)
        }

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BrokerSetting")
        do {
            let objects = try context.fetch(fetchRequest)
            return objects.compactMap { obj in
                guard let alias = obj.value(forKey: "alias") as? String,
                      let hostname = obj.value(forKey: "hostname") as? String else {
                    return nil
                }

                let subscriptions = decodeSubscriptions(obj.value(forKey: "subscriptions"))

                return BrokerInfo(
                    alias: alias,
                    hostname: hostname,
                    port: obj.value(forKey: "port") as? Int32 ?? 1883,
                    ssl: obj.value(forKey: "ssl") as? Bool ?? false,
                    untrustedSSL: obj.value(forKey: "untrustedSSL") as? Bool ?? false,
                    alpn: obj.value(forKey: "alpn") as? String,
                    authType: CLIAuthType(rawValue: (obj.value(forKey: "authType") as? Int32 ?? 0)) ?? .none,
                    username: obj.value(forKey: "username") as? String,
                    password: obj.value(forKey: "password") as? String,
                    clientID: obj.value(forKey: "clientID") as? String,
                    protocolVersion: CLIProtocolVersion(rawValue: (obj.value(forKey: "protocolVersion") as? Int32 ?? 0)) ?? .mqtt3,
                    protocolMethod: CLIProtocolMethod(rawValue: (obj.value(forKey: "protocolMethod") as? Int32 ?? 0)) ?? .mqtt,
                    basePath: obj.value(forKey: "basePath") as? String,
                    subscriptions: subscriptions
                )
            }
        } catch {
            throw BrokerLoaderError.loadFailed(error.localizedDescription)
        }
    }

    static func loadFromFile(path: String) throws -> BrokerInfo {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw BrokerLoaderError.brokerFileFailed("File not found: \(path)")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BrokerLoaderError.brokerFileFailed(error.localizedDescription)
        }

        let doc: BrokerFileDocument
        do {
            doc = try JSONDecoder().decode(BrokerFileDocument.self, from: data)
        } catch {
            throw BrokerLoaderError.brokerFileFailed("Invalid broker file format: \(error.localizedDescription)")
        }

        let b = doc.broker
        return BrokerInfo(
            alias: b.alias,
            hostname: b.hostname,
            port: Int32(b.port),
            ssl: b.ssl,
            untrustedSSL: b.untrustedSSL,
            alpn: b.alpn,
            authType: parseAuthType(b.authType),
            username: b.username,
            password: b.password,
            clientID: b.clientID,
            protocolVersion: b.protocolVersion == "mqtt5" ? .mqtt5 : .mqtt3,
            protocolMethod: b.protocolMethod == "websocket" ? .websocket : .mqtt,
            basePath: b.basePath,
            subscriptions: b.subscriptions.map { TopicSubscription(topic: $0.topic, qos: $0.qos) }
        )
    }

    private static func parseAuthType(_ name: String) -> CLIAuthType {
        switch name {
        case "usernamePassword": return .usernamePassword
        case "certificate": return .certificate
        case "both": return .both
        default: return .none
        }
    }

    static func findBroker(name: String) throws -> BrokerInfo {
        let brokers = try loadAllBrokers()

        if brokers.isEmpty {
            throw BrokerLoaderError.noBrokersConfigured
        }

        // Exact match first
        if let broker = brokers.first(where: { $0.alias == name }) {
            return broker
        }

        // Case-insensitive match
        if let broker = brokers.first(where: { $0.alias.lowercased() == name.lowercased() }) {
            return broker
        }

        throw BrokerLoaderError.brokerNotFound(name, available: brokers.map(\.alias))
    }

    // MARK: - Private

    private static func resolveExecutableDirectory() -> URL {
        // Use _NSGetExecutablePath to get the real path of the running binary,
        // regardless of how it was invoked (relative path, PATH lookup, symlink)
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        var size = UInt32(MAXPATHLEN)
        if _NSGetExecutablePath(&buffer, &size) == 0 {
            let path = String(cString: buffer)
            let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath()
            return resolved.deletingLastPathComponent()
        }

        // Fallback
        return URL(fileURLWithPath: CommandLine.arguments[0])
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
    }

    private static func decodeSubscriptions(_ value: Any?) -> [CLITopicSubscription] {
        // With transformers registered, CoreData returns a Subscriptions object
        if let subs = value as? Subscriptions {
            return subs.subscriptions
        }
        // Fallback: raw Data (if transformers weren't registered)
        if let data = value as? Data, !data.isEmpty {
            return (try? JSONDecoder().decode([CLITopicSubscription].self, from: data)) ?? []
        }
        return []
    }

    private static func findModelURL() -> URL? {
        // Resolve the real path of the executable (follows symlinks)
        let execDir = resolveExecutableDirectory()

        // Check next to the executable (development builds, standalone)
        let momdNextToExec = execDir.appendingPathComponent("MQTTAnalyzer.momd")
        if FileManager.default.fileExists(atPath: momdNextToExec.path) {
            return momdNextToExec
        }

        // Walk up from the executable to find the enclosing .app bundle
        // (CLI lives at MQTTAnalyzer.app/Contents/MacOS/mqtt-analyzer)
        var current = execDir
        while current.path != "/" {
            if current.pathExtension == "app", let appBundle = Bundle(url: current) {
                if let url = appBundle.url(forResource: "MQTTAnalyzer", withExtension: "momd") {
                    return url
                }
            }
            current = current.deletingLastPathComponent()
        }

        return nil
    }
}
