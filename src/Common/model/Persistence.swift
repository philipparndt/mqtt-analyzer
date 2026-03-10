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

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

	@Published var isLoaded = false
	private var _container: NSPersistentCloudKitContainer?

	var container: NSPersistentCloudKitContainer? {
		_container
	}

	static var path: URL? {
		let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer")
		return directoryUrl?.appendingPathComponent("data")
	}

    init(inMemory: Bool = isInMemory(), synchronous: Bool = false) {
		if synchronous {
			initializeContainer(inMemory: inMemory, synchronous: true)
		} else {
			DispatchQueue.global(qos: .userInitiated).async { [weak self] in
				self?.initializeContainer(inMemory: inMemory, synchronous: false)
			}
		}
    }

	private func initializeContainer(inMemory: Bool, synchronous: Bool = false) {
		let container = NSPersistentCloudKitContainer(name: "MQTTAnalyzer")

        if inMemory {
			let storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
			storeDescription.shouldAddStoreAsynchronously = !synchronous
			container.persistentStoreDescriptions = [storeDescription]
		} else {
			if let storeURL = PersistenceController.path {
				let storeDescription = NSPersistentStoreDescription(url: storeURL)
				storeDescription.shouldAddStoreAsynchronously = !synchronous

				if isCloudEnabled() {
					storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.de.rnd7.MQTTAnalyzer")
				}
				container.persistentStoreDescriptions = [storeDescription]

				handleCloudInit(container: container)
			}
			else {
				NSLog("no storeURL, stick with in memory db")
				let storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
				storeDescription.shouldAddStoreAsynchronously = !synchronous
				container.persistentStoreDescriptions = [storeDescription]
			}
		}

        container.loadPersistentStores { [weak self] description, error in
			self?.completeLoadPersistentStores(description: description, error: error)
			if synchronous {
				container.viewContext.automaticallyMergesChangesFromParent = true
				self?._container = container
				self?.isLoaded = true
			} else {
				DispatchQueue.main.async {
					container.viewContext.automaticallyMergesChangesFromParent = true
					self?._container = container
					self?.isLoaded = true
				}
			}
		}
    }
	
	func isCloudEnabled() -> Bool {
		if FileManager.default.ubiquityIdentityToken != nil {
			return true
		} else {
			return false
		}
	}

	func handleCloudInit(container: NSPersistentCloudKitContainer) {
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
		guard let context = container?.viewContext else { return }

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
		guard let container = controller.container else { return }

		let existing = loadAllExistingIDs(context: container.viewContext)

		for host in hosts where !existing.contains(host.id) {
			create(host: host, setting: BrokerSetting(context: container.viewContext))
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
		broker.port = Int32(host.port)
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
		broker.category = host.category
	}
}
