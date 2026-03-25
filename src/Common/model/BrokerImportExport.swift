//
//  BrokerImportExport.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-25.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import CoreData

class BrokerImportExport {

	// MARK: - Export

	/// Exports a broker to a temporary `.mqttbroker` file and returns its URL.
	/// - Parameters:
	///   - setting: The broker to export
	///   - includeSecrets: Whether to include passwords and certificate data
	static func exportBroker(_ setting: BrokerSetting, includeSecrets: Bool = true) throws -> URL {
		let model = BrokerExportModel(from: setting, includeSecrets: includeSecrets)
		let document = BrokerExportDocument(broker: model)
		let data = try document.encode()

		let fileName = sanitizeFileName(setting.aliasOrHost) + ".mqttbroker"
		let tempDir = FileManager.default.temporaryDirectory
		let fileURL = tempDir.appendingPathComponent(fileName)

		try data.write(to: fileURL)
		return fileURL
	}

	// MARK: - Import

	/// Imports a broker from a `.mqttbroker` file URL into Core Data.
	@discardableResult
	static func importBroker(from url: URL, context: NSManagedObjectContext) throws -> BrokerSetting {
		let accessing = url.startAccessingSecurityScopedResource()
		defer {
			if accessing {
				url.stopAccessingSecurityScopedResource()
			}
		}

		let data = try Data(contentsOf: url)
		let document = try BrokerExportDocument.decode(from: data)

		let broker = BrokerSetting(context: context)
		broker.id = UUID()
		document.broker.apply(to: broker)

		try context.save()
		return broker
	}

	// MARK: - Helpers

	private static func sanitizeFileName(_ name: String) -> String {
		let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
		let sanitized = name.unicodeScalars.filter { allowed.contains($0) }
		let result = String(String.UnicodeScalarView(sanitized)).trimmingCharacters(in: .whitespaces)
		return result.isEmpty ? "broker" : result
	}
}
