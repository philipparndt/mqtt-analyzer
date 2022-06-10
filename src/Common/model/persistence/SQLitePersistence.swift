//
//  SQLitePersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import GRDB

struct SQLiteBrokerSetting: Codable, FetchableRecord, PersistableRecord {
	var id: String
	var alias: String
	var hostname: String
	var port: Int
	var subscriptions: Data
	var protocolMethod: Int
	
	var basePath: String
	var ssl: Bool
	var untrustedSSL: Bool
	var protocolVersion: Int
	var authType: Int

	var username: String
	var password: String
	var certificates: Data
	var certClientKeyPassword: String
	var clientID: String
	var limitTopic: Int
	var limitMessagesBatch: Int
	var deleted: Bool
}

class SQLitePersistence: Persistence {

	let availabe: Bool
	let queue: DatabaseQueue
	let model: HostsModel?

	static let table = "SQLiteBrokerSetting"

	static var path: URL? {
		let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.de.rnd7.mqttanalyzer")
		return directoryUrl?.appendingPathComponent("brokers.sqlite")
	}

	class func createQueue() -> DatabaseQueue {
		do {
			if let dbPath = path {
				return try DatabaseQueue(path: dbPath.path)
			}
		}
		catch {
			NSLog("Unable to create database file. Using in memory database.")
		}
		
		return DatabaseQueue()
	}
		
	init(model: HostsModel? = nil) {
		self.model = model
		self.queue = SQLitePersistence.createQueue()
		
		do {
			// 2. Define the database schema
			try queue.write { db in
				if !(try db.tableExists(SQLitePersistence.table)) {
					try db.create(table: SQLitePersistence.table) { t in
						t.column("id", .text).notNull()
						t.column("alias", .text)
						t.column("hostname", .text).notNull()
						t.column("port", .integer).notNull()
						
						t.column("subscriptions", .blob).notNull()
						t.column("protocolMethod", .integer).notNull()
						t.column("basePath", .text).notNull()
						
						t.column("ssl", .boolean).notNull()
						t.column("untrustedSSL", .boolean).notNull()
						t.column("protocolVersion", .integer).notNull()
						
						t.column("authType", .integer).notNull()

						t.column("username", .text).notNull()
						t.column("password", .text).notNull()
						t.column("certificates", .blob).notNull()
						t.column("certClientKeyPassword", .text).notNull()
						
						t.column("clientID", .text).notNull()

						t.column("limitTopic", .integer).notNull()
						t.column("limitMessagesBatch", .integer).notNull()
						t.column("deleted", .boolean).notNull()
						
						t.primaryKey(["id"])
					}
				}
			}

			availabe = true
		}
		catch {
			NSLog("Error creating full text search table")
			availabe = false
		}
	}
	
	func deleteAll() {
		if !availabe {
			return
		}

		do {
			_ = try queue.write { db in
				try db.execute(sql: "DELETE FROM \(SQLitePersistence.table)")
			}
		}
		catch {
			NSLog("Error deleting all records")
		}
	}
	
	func add(setting: SQLiteBrokerSetting) {
		if !availabe {
			return
		}
		
		do {
			try queue.write { db in
				try setting.insert(db)
			}
		}
		catch {
			NSLog("Error inserting setting")
		}
	}
	
	func close() {
		if !availabe {
			return
		}

		do {
			try queue.close()
		}
		catch {
			NSLog("Error closing database")
		}
	}
}

extension SQLitePersistence {
	func delete(_ host: Host) {
		do {
			_ = try queue.write { db in
				try db.execute(sql: "DELETE FROM \(SQLitePersistence.table) WHERE id = \(host.id)")
			}
		}
		catch {
			NSLog("Error deleting record \(host.id)")
		}
	}
	
	func load() {
		if let m = model {
			m.hosts = all()
		}
	}
	
	func create(_ host: Host) {
		let transformed = PersistenceTransformer.transformToSQLite(from: host)
		add(setting: transformed)
	}
	
	func update(_ host: Host) {
		delete(host)
		create(host)
	}
}

extension SQLitePersistence {
	func insert(hosts: [Host]) {
		deleteAll()
		
		hosts
			.map { PersistenceTransformer.transformToSQLite(from: $0)}
			.forEach { add(setting: $0) }
	}
	
	func first(by name: String) -> Host? {
		if !availabe {
			return nil
		}
		
		return all()
			.filter { $0.aliasOrHost.lowercased() == name.lowercased() }
			.first
	}
	
	func all() -> [Host] {
		if !availabe {
			return []
		}
		do {
			let settings: [SQLiteBrokerSetting] = try queue.read { db in
				try SQLiteBrokerSetting.fetchAll(db)
			}
			
			return settings
				.map { PersistenceTransformer.transform(from: $0) }
		}
		catch {
			NSLog("Error reading settings")
			return []
		}
	}
	
	func allNames() -> [String] {
		if !availabe {
			return []
		}
		do {
			let settings: [SQLiteBrokerSetting] = try queue.read { db in
				try SQLiteBrokerSetting.fetchAll(db)
			}
			
			return settings
				.map { PersistenceTransformer.transform(from: $0) }
				.map { $0.aliasOrHost }
		}
		catch {
			NSLog("Error reading settings")
			return []
		}
	}
}
