//
//  BrokerExportModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-25.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// JSON schema for `.mqttbroker` files.
/// This format is shared between MQTT apps for broker configuration exchange.
/// See docs/mqttbroker-schema.json for the full JSON Schema definition.
struct BrokerExportDocument: Codable {
	static let currentVersion = 1

	let version: Int
	let broker: BrokerExportModel

	init(broker: BrokerExportModel) {
		self.version = Self.currentVersion
		self.broker = broker
	}
}

struct BrokerExportModel: Codable {
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
	let subscriptions: [BrokerExportSubscription]
	let certificates: [BrokerExportCertificate]?
	let certClientKeyPassword: String?
	let category: String?
	let limitTopic: Int
	let limitMessagesBatch: Int
}

struct BrokerExportSubscription: Codable {
	let topic: String
	let qos: Int
}

/// Certificate embedded in the export file.
/// The `data` field contains the certificate file contents as base64.
struct BrokerExportCertificate: Codable {
	let name: String
	let type: String
	let data: String?
}

// MARK: - Export from BrokerSetting

extension BrokerExportModel {
	init(from setting: BrokerSetting, includeSecrets: Bool = true) {
		self.alias = setting.alias
		self.hostname = setting.hostname
		self.port = Int(setting.port)
		self.protocolMethod = setting.protocolMethod == .websocket ? "websocket" : "mqtt"
		self.protocolVersion = setting.protocolVersion == .mqtt5 ? "mqtt5" : "mqtt3"
		self.basePath = setting.basePath
		self.ssl = setting.ssl
		self.untrustedSSL = setting.untrustedSSL
		self.alpn = setting.alpn
		self.authType = Self.authTypeName(setting.authType)
		self.username = setting.username
		self.password = includeSecrets ? setting.password : nil
		self.clientID = setting.clientID
		self.subscriptions = (setting.subscriptions?.subscriptions ?? []).map {
			BrokerExportSubscription(topic: $0.topic, qos: $0.qos)
		}
		let files = setting.certificates?.files ?? []
		self.certificates = includeSecrets
			? Self.exportCertificates(files)
			: Self.exportCertificateMetadata(files)
		self.certClientKeyPassword = includeSecrets ? setting.certClientKeyPassword : nil
		self.category = setting.category
		self.limitTopic = Int(setting.limitTopic)
		self.limitMessagesBatch = Int(setting.limitMessagesBatch)
	}

	private static func exportCertificates(_ files: [CertificateFile]) -> [BrokerExportCertificate]? {
		let result = files.map { cert in
			let base64Data: String? = {
				guard let url = try? cert.getFullPath(),
					  let data = try? Data(contentsOf: url) else {
					return nil
				}
				return data.base64EncodedString()
			}()

			return BrokerExportCertificate(
				name: cert.name,
				type: certFileTypeName(cert.type),
				data: base64Data
			)
		}
		return result.isEmpty ? nil : result
	}

	/// Exports certificate metadata only (no file data).
	private static func exportCertificateMetadata(_ files: [CertificateFile]) -> [BrokerExportCertificate]? {
		let result = files.map { cert in
			BrokerExportCertificate(
				name: cert.name,
				type: certFileTypeName(cert.type),
				data: nil
			)
		}
		return result.isEmpty ? nil : result
	}

	private static func authTypeName(_ type: HostAuthenticationType) -> String {
		switch type {
		case .none: return "none"
		case .usernamePassword: return "usernamePassword"
		case .certificate: return "certificate"
		case .both: return "both"
		}
	}

	private static func certFileTypeName(_ type: CertificateFileType) -> String {
		switch type {
		case .p12: return "p12"
		case .serverCA: return "serverCA"
		case .client: return "client"
		case .clientKey: return "clientKey"
		case .undefined: return "undefined"
		}
	}
}

// MARK: - Import to BrokerSetting

extension BrokerExportModel {
	func apply(to target: BrokerSetting) {
		target.alias = alias
		target.hostname = hostname
		target.port = Int32(port)
		target.protocolMethod = protocolMethod == "websocket" ? .websocket : .mqtt
		target.protocolVersion = protocolVersion == "mqtt5" ? .mqtt5 : .mqtt3
		target.basePath = basePath
		target.ssl = ssl
		target.untrustedSSL = untrustedSSL
		target.alpn = alpn
		target.authType = Self.parseAuthType(authType)
		target.username = username
		target.password = password
		target.clientID = clientID
		target.subscriptions = Subscriptions(subscriptions.map {
			TopicSubscription(topic: $0.topic, qos: $0.qos)
		})
		target.certClientKeyPassword = certClientKeyPassword
		target.category = category
		target.limitTopic = Int32(limitTopic)
		target.limitMessagesBatch = Int32(limitMessagesBatch)

		if let exportedCerts = certificates {
			let imported = Self.importCertificates(exportedCerts)
			target.certificates = Certificates(imported)
			target.certificateStorageLocation = .local
		}
	}

	private static func importCertificates(_ exported: [BrokerExportCertificate]) -> [CertificateFile] {
		return exported.compactMap { cert in
			// Write the certificate data to the local documents directory
			if let base64 = cert.data,
			   let data = Data(base64Encoded: base64),
			   let localDir = CloudDataManager.instance.getLocalDocumentDiretoryURL() {
				let fileURL = localDir.appendingPathComponent(cert.name)
				try? data.write(to: fileURL)
			}

			let hash: String? = {
				guard let localDir = CloudDataManager.instance.getLocalDocumentDiretoryURL() else { return nil }
				return computeFileHash(url: localDir.appendingPathComponent(cert.name))
			}()

			return CertificateFile(
				name: cert.name,
				location: .local,
				type: parseCertFileType(cert.type),
				fileHash: hash
			)
		}
	}

	private static func parseAuthType(_ name: String) -> HostAuthenticationType {
		switch name {
		case "usernamePassword": return .usernamePassword
		case "certificate": return .certificate
		case "both": return .both
		default: return .none
		}
	}

	private static func parseCertFileType(_ name: String) -> CertificateFileType {
		switch name {
		case "p12": return .p12
		case "serverCA": return .serverCA
		case "client": return .client
		case "clientKey": return .clientKey
		default: return .undefined
		}
	}
}

// MARK: - Encoding / Decoding

extension BrokerExportDocument {
	func encode() throws -> Data {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		return try encoder.encode(self)
	}

	static func decode(from data: Data) throws -> BrokerExportDocument {
		return try JSONDecoder().decode(BrokerExportDocument.self, from: data)
	}
}
