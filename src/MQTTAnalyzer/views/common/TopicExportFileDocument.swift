//
//  TopicExportFileDocument.swift
//  MQTTAnalyzer
//
//  FileDocument + helpers for exporting a topic subtree snapshot to a file.
//

import SwiftUI
import UniformTypeIdentifiers

struct TopicExportFileDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.json, .plainText] }

	var text: String

	init(text: String) {
		self.text = text
	}

	init(configuration: ReadConfiguration) throws {
		if let data = configuration.file.regularFileContents,
		   let string = String(data: data, encoding: .utf8) {
			text = string
		} else {
			text = ""
		}
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let data = text.data(using: .utf8) ?? Data()
		return FileWrapper(regularFileWithContents: data)
	}
}

extension TopicExportFormat {
	var contentType: UTType {
		switch self {
		case .json: return .json
		case .yaml: return UTType(filenameExtension: "yaml") ?? .plainText
		}
	}
}

enum TopicExportNaming {
	/// Derives a safe default filename (without extension) from a qualified topic name.
	static func filename(for qualifiedTopic: String) -> String {
		let base = qualifiedTopic.isEmpty ? "root" : qualifiedTopic
		let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
		let sanitized = base.components(separatedBy: invalid).joined(separator: "_")
		return sanitized.isEmpty ? "root" : sanitized
	}
}
