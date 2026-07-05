//
//  JSONValue.swift
//  MQTTAnalyzer
//
//  A Codable representation of an arbitrary JSON value. Used as the generic
//  tree the YAML emitter walks when rendering a subtree export.
//

import Foundation

indirect enum JSONValue: Codable, Equatable {
	case string(String)
	case int(Int)
	case double(Double)
	case bool(Bool)
	case null
	case array([JSONValue])
	case object([String: JSONValue])

	// MARK: - Decoding

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if container.decodeNil() {
			self = .null
		} else if let value = try? container.decode(Bool.self) {
			self = .bool(value)
		} else if let value = try? container.decode(Int.self) {
			self = .int(value)
		} else if let value = try? container.decode(Double.self) {
			self = .double(value)
		} else if let value = try? container.decode(String.self) {
			self = .string(value)
		} else if let value = try? container.decode([JSONValue].self) {
			self = .array(value)
		} else if let value = try? container.decode([String: JSONValue].self) {
			self = .object(value)
		} else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Unsupported JSON value"
			)
		}
	}

	// MARK: - Encoding

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .string(let value): try container.encode(value)
		case .int(let value): try container.encode(value)
		case .double(let value): try container.encode(value)
		case .bool(let value): try container.encode(value)
		case .null: try container.encodeNil()
		case .array(let value): try container.encode(value)
		case .object(let value): try container.encode(value)
		}
	}
}

