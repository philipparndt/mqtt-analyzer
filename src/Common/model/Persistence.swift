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
/*
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
*/
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = isInMemory()) {
        container = NSPersistentCloudKitContainer(name: "MQTTAnalyzer")
		
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
		else {
			#if DEBUG
			do {
				// Use the container to initialize the development schema.
				try container.initializeCloudKitSchema(options: [])
			} catch {
				// Handle any errors.
			}
			#endif
		}
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
				// MARK: FIXME
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
		
        container.viewContext.automaticallyMergesChangesFromParent = true
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
	class func createAll(hosts: [Host]) {
		let controller = PersistenceController.shared
		let container = controller.container
		
		let existing = loadAllExistingIDs(context: container.viewContext)
		
		for host in hosts {
			if !existing.contains(host.ID) {
				create(host: host, context: container.viewContext)
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
	
	class func create(host: Host, context: NSManagedObjectContext) {
		let broker = BrokerSetting(context: context)
		broker.id = UUID.init(uuidString: host.ID)
		broker.alias = host.alias
		broker.clientID = host.clientID

		broker.hostname = host.hostname
		broker.port = Int32(host.port)
		broker.basePath = host.basePath
		broker.protocolMethod = host.protocolMethod
		broker.protocolVersion = host.protocolVersion

		broker.ssl = host.ssl
		broker.untrustedSSL = host.untrustedSSL

		broker.authType = host.auth
		broker.username = host.username
		broker.password = host.password
		broker.certificates = Certificates(host.certificates)
		broker.certClientKeyPassword = host.certClientKeyPassword

		broker.limitMessagesBatch = Int32(host.limitMessagesBatch)
		broker.limitTopic = Int32(host.limitTopic)
		
		broker.subscriptions = Subscriptions(host.subscriptions)
	}
}
