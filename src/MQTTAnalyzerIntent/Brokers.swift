//
//  Brokers.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

func loadBrokers() -> [NSString] {
	let controller = PersistenceController.shared
	let container = controller.container
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

func firstBroker(by name: String) -> Host? {
	let controller = PersistenceController.shared
	let container = controller.container
	let fetchRequest = BrokerSetting.fetchRequest()
	do {
		let objects = try container.viewContext.fetch(fetchRequest)
		
		if let first = objects.first(where: { $0.aliasOrHost == name }) {
			return PersistenceTransformer.transform(from: first)
		}
	}
	catch {
		NSLog("Error loading all existingIDs from CoreData")
	}
	
	return nil
}
