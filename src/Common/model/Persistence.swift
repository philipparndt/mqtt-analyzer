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
	@Published var loadError: String?
	private var _container: NSPersistentCloudKitContainer?

	var container: NSPersistentCloudKitContainer? {
		_container
	}

	static var path: URL? {
		let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer")
		return directoryUrl?.appendingPathComponent("data")
	}

    init(inMemory: Bool = isInMemory(), synchronous: Bool = false) {
		// For UI testing (inMemory), always use synchronous initialization
		// to ensure stubs are created before the app UI appears
		let useSynchronous = synchronous || inMemory
		if useSynchronous {
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
			}
			else {
				NSLog("no storeURL, stick with in memory db")
				let storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
				storeDescription.shouldAddStoreAsynchronously = !synchronous
				container.persistentStoreDescriptions = [storeDescription]
			}
		}

        container.loadPersistentStores { [weak self] description, error in
			if let error = error {
				NSLog("Failed to load persistent store: \(error)")
				self?.handleStoreLoadFailure(
					container: container,
					description: description,
					error: error,
					inMemory: inMemory,
					synchronous: synchronous
				)
				return
			}

			self?.activateContainer(container, synchronous: synchronous)
		}
    }

	private func activateContainer(_ container: NSPersistentCloudKitContainer, synchronous: Bool) {
		#if DEBUG
		do {
			try container.initializeCloudKitSchema(options: [])
		} catch {
			NSLog("Unexpected error while initializeCloudKitSchema \(error)")
		}
		#endif

		if synchronous {
			container.viewContext.automaticallyMergesChangesFromParent = true
			_container = container
			isLoaded = true
		} else {
			DispatchQueue.main.async { [weak self] in
				container.viewContext.automaticallyMergesChangesFromParent = true
				self?._container = container
				self?.isLoaded = true
			}
		}
	}

	private func handleStoreLoadFailure(
		container: NSPersistentCloudKitContainer,
		description: NSPersistentStoreDescription,
		error: Error,
		inMemory: Bool,
		synchronous: Bool
	) {
		guard !inMemory, let storeURL = description.url else {
			setLoadError("Failed to load data: \(error.localizedDescription)", synchronous: synchronous)
			return
		}

		NSLog("Attempting to recover by removing incompatible store at \(storeURL)")

		// Remove the incompatible store files
		let fileManager = FileManager.default
		let storePath = storeURL.path
		for suffix in ["", "-wal", "-shm"] {
			let file = storePath + suffix
			if fileManager.fileExists(atPath: file) {
				try? fileManager.removeItem(atPath: file)
			}
		}

		// Also remove any CloudKit metadata
		let ckDirectory = storeURL.deletingLastPathComponent()
			.appendingPathComponent("ckAssets")
		if fileManager.fileExists(atPath: ckDirectory.path) {
			try? fileManager.removeItem(at: ckDirectory)
		}

		// Retry loading with a fresh store
		container.loadPersistentStores { [weak self] _, retryError in
			if let retryError = retryError {
				NSLog("Recovery failed: \(retryError)")
				self?.setLoadError(
					"Database could not be recovered. Please reinstall the app.",
					synchronous: synchronous
				)
				return
			}

			NSLog("Successfully recovered with fresh store")
			self?.activateContainer(container, synchronous: synchronous)
		}
	}

	private func setLoadError(_ message: String, synchronous: Bool) {
		if synchronous {
			loadError = message
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.loadError = message
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
