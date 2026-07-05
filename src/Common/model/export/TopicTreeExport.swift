//
//  TopicTreeExport.swift
//  MQTTAnalyzer
//
//  Snapshot model + serializers for exporting the recent message of a topic
//  and all of its descendant topics as JSON or YAML.
//

import Foundation

/// The most recent message of a single topic within a subtree snapshot.
struct TopicMessageExport: Codable, Equatable {
	let topic: String
	/// The payload is preserved verbatim: text messages keep their raw string,
	/// binary messages are Base64-encoded so no data is lost. It is never
	/// re-serialized into the export format.
	let payload: String
	/// `"base64"` when `payload` holds Base64-encoded binary data; omitted for
	/// plain UTF-8 text payloads.
	let payloadEncoding: String?
	let retain: Bool
	let qos: Int
	let timestamp: String
}

/// A snapshot of the recent message of a topic and all of its descendants.
struct TopicTreeExport: Codable, Equatable {
	let root: String
	let exportedAt: String
	let messages: [TopicMessageExport]
}

extension TopicTreeExport {
	private static let timestampFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]
		return formatter
	}()

	/// Builds a snapshot from a topic node, collecting the latest message of the
	/// node and every descendant that has at least one message. Entries are
	/// sorted by qualified topic name for deterministic output.
	init(node: TopicTree, exportedAt: Date) {
		let messages = node.recusiveAllMessages.compactMap { tree -> TopicMessageExport? in
			guard let message = tree.messages.last else { return nil }
			let payload = message.payload
			let isBinary = payload.isBinary
			return TopicMessageExport(
				topic: tree.nameQualified,
				payload: isBinary ? Data(payload.data).base64EncodedString() : payload.dataString,
				payloadEncoding: isBinary ? "base64" : nil,
				retain: message.metadata.retain,
				qos: Int(message.metadata.qos),
				timestamp: TopicTreeExport.timestampFormatter.string(from: message.metadata.date)
			)
		}

		self.root = node.nameQualified
		self.exportedAt = TopicTreeExport.timestampFormatter.string(from: exportedAt)
		self.messages = messages
	}
}

/// The serialization formats supported for a subtree export.
enum TopicExportFormat {
	case json
	case yaml

	var fileExtension: String {
		switch self {
		case .json: return "json"
		case .yaml: return "yaml"
		}
	}
}

enum TopicTreeExporter {
	/// Serializes the subtree snapshot of `node` to the requested format.
	static func serialize(node: TopicTree, format: TopicExportFormat, exportedAt: Date = Date()) -> String {
		let export = TopicTreeExport(node: node, exportedAt: exportedAt)
		switch format {
		case .json:
			return json(export)
		case .yaml:
			return yaml(export)
		}
	}

	static func json(_ export: TopicTreeExport) -> String {
		let encoder = JSONEncoder()
		// Keep slashes unescaped so topics and Base64 payloads stay readable.
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		guard let data = try? encoder.encode(export),
			  let string = String(data: data, encoding: .utf8) else {
			return ""
		}
		return string
	}

	static func yaml(_ export: TopicTreeExport) -> String {
		let encoder = JSONEncoder()
		guard let data = try? encoder.encode(export),
			  let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
			return ""
		}
		return YAMLEmitter.emit(value)
	}
}
