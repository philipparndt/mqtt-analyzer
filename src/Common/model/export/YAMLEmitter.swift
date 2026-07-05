//
//  YAMLEmitter.swift
//  MQTTAnalyzer
//
//  A small, self-contained block-style YAML emitter for `JSONValue` trees.
//  Object keys are sorted to produce deterministic, diff-friendly output.
//  Strings that would otherwise need quoting/escaping (e.g. a JSON payload)
//  are emitted verbatim as block-literal (`|-`) scalars.
//

import Foundation

enum YAMLEmitter {
	static func emit(_ value: JSONValue) -> String {
		switch classify(value) {
		case .inline(let token):
			return token + "\n"
		case .block(let contentLines):
			return (["|-"] + contentLines.map { "  " + $0 }).joined(separator: "\n") + "\n"
		default:
			return lines(for: value, indent: 0).joined(separator: "\n") + "\n"
		}
	}

	// MARK: - Rendering

	private static func lines(for value: JSONValue, indent: Int) -> [String] {
		let pad = String(repeating: "  ", count: indent)
		let childPad = String(repeating: "  ", count: indent + 1)

		switch value {
		case .array(let array):
			if array.isEmpty { return [pad + "[]"] }
			var result: [String] = []
			for item in array {
				switch classify(item) {
				case .inline(let token):
					result.append(pad + "- " + token)
				case .empty(let token):
					result.append(pad + "- " + token)
				case .block(let contentLines):
					result.append(pad + "- |-")
					result.append(contentsOf: contentLines.map { childPad + $0 })
				case .container:
					let childLines = lines(for: item, indent: indent + 1)
					let firstContent = String(childLines[0].dropFirst((indent + 1) * 2))
					result.append(pad + "- " + firstContent)
					result.append(contentsOf: childLines.dropFirst())
				}
			}
			return result

		case .object(let dictionary):
			if dictionary.isEmpty { return [pad + "{}"] }
			var result: [String] = []
			for key in dictionary.keys.sorted() {
				let child = dictionary[key]!
				let renderedKey = needsQuoting(key) ? quote(key) : key
				switch classify(child) {
				case .inline(let token):
					result.append(pad + renderedKey + ": " + token)
				case .empty(let token):
					result.append(pad + renderedKey + ": " + token)
				case .block(let contentLines):
					result.append(pad + renderedKey + ": |-")
					result.append(contentsOf: contentLines.map { childPad + $0 })
				case .container:
					result.append(pad + renderedKey + ":")
					result.append(contentsOf: lines(for: child, indent: indent + 1))
				}
			}
			return result

		default:
			return [pad + (inlineScalar(value) ?? "null")]
		}
	}

	// MARK: - Classification

	private enum Rendered {
		case inline(String)
		case block([String])
		case container
		case empty(String)
	}

	private static func classify(_ value: JSONValue) -> Rendered {
		switch value {
		case .null: return .inline("null")
		case .bool(let value): return .inline(value ? "true" : "false")
		case .int(let value): return .inline(String(value))
		case .double(let value): return .inline(formatDouble(value))
		case .string(let value): return renderString(value)
		case .array(let array): return array.isEmpty ? .empty("[]") : .container
		case .object(let object): return object.isEmpty ? .empty("{}") : .container
		}
	}

	/// Renders a string either as a single inline scalar (plain or double-quoted)
	/// or, when it would otherwise need escaping and is block-safe, as the content
	/// lines of a block-literal (`|-`) scalar so the value is preserved verbatim.
	private static func renderString(_ string: String) -> Rendered {
		if string.isEmpty { return .inline("\"\"") }
		if !needsQuoting(string) { return .inline(string) }
		if isBlockSafe(string) { return .block(string.components(separatedBy: "\n")) }
		return .inline(quote(string))
	}

	private static func inlineScalar(_ value: JSONValue) -> String? {
		if case .inline(let token) = classify(value) { return token }
		return nil
	}

	// MARK: - Scalars

	private static func formatDouble(_ value: Double) -> String {
		if value == value.rounded() && abs(value) < 1e15 {
			return String(format: "%.1f", value)
		}
		return String(value)
	}

	/// A string is safe to emit as a `|-` block literal when it does not rely on
	/// leading/trailing whitespace or carriage returns that block scalars cannot
	/// faithfully reproduce. `|-` strips the final line break, so a trailing
	/// newline would be lost - such strings fall back to double quoting.
	private static func isBlockSafe(_ string: String) -> Bool {
		if string.hasPrefix(" ") || string.hasPrefix("\t") { return false }
		if string.hasSuffix("\n") { return false }
		if string.contains("\r") { return false }
		for line in string.components(separatedBy: "\n") where line.hasSuffix(" ") || line.hasSuffix("\t") {
			return false
		}
		return true
	}

	// MARK: - Quoting

	private static let reservedScalars: Set<String> = [
		"true", "false", "null", "yes", "no", "on", "off", "~",
		"True", "False", "Null", "Yes", "No", "On", "Off",
		"TRUE", "FALSE", "NULL", "YES", "NO", "ON", "OFF"
	]

	private static let leadingIndicators: Set<Character> = [
		"!", "&", "*", "-", "?", ":", ",", "[", "]", "{", "}",
		"#", "|", ">", "@", "`", "\"", "'", "%", " "
	]

	private static func needsQuoting(_ string: String) -> Bool {
		if string.isEmpty { return true }
		if reservedScalars.contains(string) { return true }
		if Int(string) != nil || Double(string) != nil { return true }
		if let first = string.first, leadingIndicators.contains(first) { return true }
		if let last = string.last, last == " " || last == ":" { return true }
		if string.contains(": ") || string.contains(" #") { return true }
		if string.contains("\n") || string.contains("\t") || string.contains("#") { return true }
		return false
	}

	private static func quote(_ string: String) -> String {
		var result = "\""
		for scalar in string.unicodeScalars {
			switch scalar {
			case "\\": result += "\\\\"
			case "\"": result += "\\\""
			case "\n": result += "\\n"
			case "\t": result += "\\t"
			case "\r": result += "\\r"
			default: result.unicodeScalars.append(scalar)
			}
		}
		result += "\""
		return result
	}
}
