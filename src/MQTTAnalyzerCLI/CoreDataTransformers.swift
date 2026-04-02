//
//  CoreDataTransformers.swift
//  MQTTAnalyzerCLI
//
//  Provides CoreData value transformers so the model loads without warnings.
//  These types mirror the Common definitions used by the app.
//

import Foundation

// MARK: - Types required by CoreData transformers

struct TopicSubscription: Codable {
    var topic: String
    var qos: Int
}

enum CertificateLocation: Int, Codable {
    case cloud = 0
    case local = 1
}

enum CertificateFileType: Int, Codable {
    case p12 = 0
    case serverCA = 1
    case client = 2
    case clientKey = 3
    case undefined = 4
}

struct CertificateFile: Codable, Equatable {
    let name: String
    let location: CertificateLocation
    var type = CertificateFileType.undefined
    var fileHash: String?
}

// MARK: - Subscriptions transformer

@objc(Subscriptions)
public class Subscriptions: NSObject {
    var subscriptions: [TopicSubscription]

    init(_ subscriptions: [TopicSubscription] = []) {
        self.subscriptions = subscriptions
    }
}

@objc(SubscriptionValueTransformer)
public final class SubscriptionValueTransformer: ValueTransformer {
    public override class func transformedValueClass() -> AnyClass { Subscriptions.self }
    public override class func allowsReverseTransformation() -> Bool { true }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let subscriptions = value as? Subscriptions else { return nil }
        return try? JSONEncoder().encode(subscriptions.subscriptions)
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data, !data.isEmpty else { return Subscriptions() }
        let decoded = (try? JSONDecoder().decode([TopicSubscription].self, from: data)) ?? []
        return Subscriptions(decoded)
    }
}

// MARK: - Certificates transformer

@objc(Certificates)
public class Certificates: NSObject {
    var files: [CertificateFile]

    init(_ files: [CertificateFile] = []) {
        self.files = files
    }
}

@objc(CertificateValueTransformer)
public final class CertificateValueTransformer: ValueTransformer {
    public override class func transformedValueClass() -> AnyClass { Certificates.self }
    public override class func allowsReverseTransformation() -> Bool { true }

    public override func transformedValue(_ value: Any?) -> Any? {
        guard let certificates = value as? Certificates else { return nil }
        return try? JSONEncoder().encode(certificates.files)
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data, !data.isEmpty else { return Certificates() }
        let decoded = (try? JSONDecoder().decode([CertificateFile].self, from: data)) ?? []
        return Certificates(decoded)
    }
}
