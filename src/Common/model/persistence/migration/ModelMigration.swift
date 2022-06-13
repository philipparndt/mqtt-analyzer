//
//  ModelMigration.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 12.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CoreData

class ModelMigration {
	static let migratedToCoreData = "migratedToCoreData"
	
	class func migrateToCoreData() {
		let defaults = UserDefaults.standard
		if !defaults.bool(forKey: migratedToCoreData) {
			let persistence = SQLitePersistence()
			let hosts = persistence.all()

			let controller = PersistenceController.shared
			let container = controller.container
			
			let existing = loadAllExistingIDs(context: container.viewContext)
			
			for host in hosts {
				if !existing.contains(host.ID) {
					create(host: host, context: container.viewContext)
				}
			}
			
			controller.save()
			defaults.set(true, forKey: migratedToCoreData)
		}
	}
	
	class func loadAllExistingIDs(context: NSManagedObjectContext) -> Set<String> {
		let fetchRequest = BrokerSetting.fetchRequest()
		do {
			let objects = try context.fetch(fetchRequest)
			return Set(objects.map { $0.id?.uuidString ?? "<no id>" })
		}
		catch {
			NSLog("Error loading all existingIDs from CoreData")
			return []
		}
	}
	
	class func create(host: Host, context: NSManagedObjectContext) {
	    let broker = BrokerSetting(context: context)
		broker.id = UUID.init(uuidString: host.ID)
		broker.alias = host.alias
		broker.clientID = host.clientID

		broker.hostname = host.hostname
		broker.port = Int32(host.port)
		broker.basePath = host.basePath
		broker.protocolMethod = Int32(PersistenceTransformer.transformConnectionMethod(host.protocolMethod))
		broker.protocolVersion = Int32(PersistenceTransformer.transformProtocolVersion(host.protocolVersion))

		broker.ssl = host.ssl
		broker.untrustedSSL = host.untrustedSSL

		broker.authType = Int32(PersistenceTransformer.transformAuth(host.auth))
		broker.username = host.username
		broker.password = host.password
		broker.certificates = PersistenceEncoder.encode(certificates: host.certificates)
		broker.certClientKeyPassword = host.certClientKeyPassword

		broker.limitMessagesBatch = Int32(host.limitMessagesBatch)
		broker.limitTopic = Int32(host.limitTopic)

		broker.subscriptions = PersistenceEncoder.encode(subscriptions: host.subscriptions)
	}
}
