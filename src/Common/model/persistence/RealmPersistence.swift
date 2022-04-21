//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

public class RealmPersistence: Persistence {
	let model: HostsModel
	let realm: Realm
	var token: NotificationToken?
	
	static var realmPath: URL? {
		let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer")
		return directoryUrl?.appendingPathComponent("default.realm")
	}
	
	static var realmConfig: Realm.Configuration {
		var config = Realm.Configuration(fileURL: realmPath)
		config.deleteRealmIfMigrationNeeded = true
		return config
	}
	
	init?(model: HostsModel) {
		self.model = model
		
		if let realm = RealmPersistence.initRealm() {
			self.realm = realm
		}
		else {
			return nil
		}
	}
	
	class func initRealm() -> Realm? {
		do {
			return try Realm()
		}
		catch {
			NSLog("Unable to initialize persistence, using stub persistence. \(error)")
			return nil
		}
		
	}
	
	func create(_ host: Host) {
		if CommandLine.arguments.contains("--ui-testing") {
			return
		}

		let setting = PersistenceTransformer.transformToRealm(from: host)
		
		do {
			try realm.write {
				realm.add(setting)
			}
		}
		catch {
			NSLog("Error creating entry in database: \(error.localizedDescription)")
		}
	}
		
	func update(_ host: Host) {
		let settings = realm.objects(HostSetting.self)
			.filter("id = %@", host.ID)
		
		if let setting = settings.first {
			do {
				try realm.write {
					PersistenceTransformer.copy(from: host, to: setting)
				}
			}
			catch {
				NSLog("Error updating database: \(error.localizedDescription)")
			}
			
		}
	}
	
	func delete(_ host: Host) {
		let settings = realm.objects(HostSetting.self)
			.filter("id = %@", host.ID)
		
		if let setting = settings.first {
			do {
				try realm.write {
					setting.isDeleted = true
				}
			}
			catch {
				NSLog("Error deleting entry from database: \(error.localizedDescription)")
			}
		}
		
		load()
	}
	
	func load() {
		HostSettingExamples.inititalize(realm: realm)
		
		let settings = realm.objects(HostSetting.self)
		
		token?.invalidate()
		
		token = settings.observe { (_: RealmCollectionChange) in
			self.pushModel(settings: settings)
		}
	}
	
	func first(name: String) -> Host? {
		return filter(settings: realm.objects(HostSetting.self))
			.filter { $0.aliasOrHost.lowercased() == name.lowercased() }
			.first
	}
	
	private func filter(settings: Results<HostSetting>) -> [Host] {
		return settings
			.filter { !$0.isDeleted }
			.map { PersistenceTransformer.transform(from: $0) }
	}
	
	private func pushModel(settings: Results<HostSetting>) {
		let hosts = filter(settings: settings)
		
		DispatchQueue.main.async {
			self.model.hosts = hosts
			
			let sqlite = SQLitePersistence()
			sqlite.insert(hosts: hosts)
			sqlite.close()
		}
	}
}
