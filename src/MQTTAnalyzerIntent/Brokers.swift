//
//  Brokers.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

// Intent extensions need synchronous initialization because the data must be
// available immediately when provideBrokerOptionsCollection is called
private let intentPersistenceController = PersistenceController(synchronous: true)

func loadBrokers() -> [NSString] {
	let controller = intentPersistenceController
	guard let container = controller.container else { return [] }
	let fetchRequest = BrokerSetting.fetchRequest()
	do {
		let objects = try container.viewContext.fetch(fetchRequest)
		return objects
			.map { $0.aliasOrHost }
			.map { $0 as NSString }
	}
	catch {
		NSLog("Error loading all existingIDs from CoreData")
		return []
	}
}

func firstBroker(by name: String) -> BrokerSetting? {
	let controller = intentPersistenceController
	guard let container = controller.container else { return nil }
	let fetchRequest = BrokerSetting.fetchRequest()
	do {
		let objects = try container.viewContext.fetch(fetchRequest)

		if let first = objects.first(where: { $0.aliasOrHost == name }) {
			return first
		}
	}
	catch {
		NSLog("Error loading all existingIDs from CoreData")
	}

	return nil
}
