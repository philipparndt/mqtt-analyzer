//
//  Persistence.swift
//  HomeWidgets
//
//  Created by Philipp Arndt on 2022-03-19.
//

import CoreData

func isInMemory() -> Bool {
	#if DEBUG
	return CommandLine.arguments.contains("--ui-testing")
	#else
	return false
	#endif
}

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

	static var path: URL? {
		let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer")
		return directoryUrl?.appendingPathComponent("data")
	}
	
    init(inMemory: Bool = isInMemory()) {
		
        container = NSPersistentCloudKitContainer(name: "MQTTAnalyzer")
		initInMemory()
		
        if !inMemory {
			if let storeURL = PersistenceController.path {
				let storeDescription = NSPersistentStoreDescription(url: storeURL)
				storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.de.rnd7.MQTTAnalyzer")
				container.persistentStoreDescriptions = [storeDescription]

				handleCloudInit()
			}
			else {
				NSLog("no storeURL, stick with in memory db")
			}
		}
		
        container.loadPersistentStores(completionHandler: completeLoadPersistentStores)
		
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
	
	func initInMemory() {
		container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
	}

	func handleCloudInit() {
		#if DEBUG
		do {
			// Use the container to initialize the development schema.
			try container.initializeCloudKitSchema(options: [])
		} catch {
			NSLog("Unexpected error while initializeCloudKitSchema \(error)")
		}
		#endif
	}
	
	func completeLoadPersistentStores(description: NSPersistentStoreDescription, error: Error?) {
		if let error = error as NSError? {
			/*
			 Typical reasons for an error here include:
			 * The parent directory does not exist, cannot be created, or disallows writing.
			 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
			 * The device is out of space.
			 * The store could not be migrated to the current model version.
			 Check the error message to determine what the actual problem was.
			 */
			#if DEBUG
			fatalError("Unresolved error \(error), \(error.userInfo)")
			#else
			NSLog("Unresolved error \(error), \(error.userInfo)")
			#endif
		}
	}
	
	func createStubs() {
		PersistenceHelper.createAll(hosts: [
			HostSettingExamples.example1(),
			 HostSettingExamples.example2(),
			 HostSettingExamples.exampleRnd7(),
			 HostSettingExamples.exampleLocalhost()
		 ])
	}
	
	func save() {
		let context = container.viewContext

		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Show some error here
			}
		}
	}
}

class PersistenceHelper {
	class func createAll(hosts: [SQLiteBrokerSetting]) {
		let controller = PersistenceController.shared
		let container = controller.container
		
		let existing = loadAllExistingIDs(context: container.viewContext)
		
		for host in hosts {
			if !existing.contains(host.id) {
				create(host: host, setting: BrokerSetting(context: container.viewContext))
			}
		}
		
		controller.save()
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
	
	class func create(host: SQLiteBrokerSetting, setting broker: BrokerSetting) {
		broker.id = UUID.init(uuidString: host.id)
		broker.alias = host.alias
		broker.clientID = host.clientID

		broker.hostname = host.hostname
		broker.port = Int16(host.port)
		broker.basePath = host.basePath
		broker.protocolMethod = PersistenceTransformer.transformConnectionMethod(Int8(host.protocolMethod))
		broker.protocolVersion = PersistenceTransformer.transformProtocolVersion(Int8(host.protocolVersion))

		broker.ssl = host.ssl
		broker.untrustedSSL = host.untrustedSSL

		broker.authType = PersistenceTransformer.transformAuth(Int8(host.authType))
		broker.username = host.username
		broker.password = host.password
		broker.certificates = Certificates(CertificateValueTransformer.decode(certificates: host.certificates))
		broker.certClientKeyPassword = host.certClientKeyPassword

		broker.limitMessagesBatch = Int32(host.limitMessagesBatch)
		broker.limitTopic = Int32(host.limitTopic)
		
		broker.subscriptions = Subscriptions(SubscriptionValueTransformer.decode(subscriptions: host.subscriptions))
	}
}
