//
//  SearchIndex.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-25.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import GRDB

struct Message: Codable, FetchableRecord, PersistableRecord {
	let topic: String
	let payload: String
}

class SearchIndex {
	let inMemoryDBQueue = DatabaseQueue()
	let availabe: Bool
	
	init() {
		do {
			// 2. Define the database schema
			try inMemoryDBQueue.write { db in
				try db.create(virtualTable: "message", using: FTS4()) { t in
					t.column("topic")
					t.column("payload")
				}
			}

			availabe = true
		}
		catch {
			NSLog("Error creating full text search table")
			availabe = false
		}
	}
	
	// Not thread safe - just for unit testing
	var execSync = false
	
	func add(message: MsgMessage) {
		if !message.payload.isBinary {
			if execSync {
				self.addToIndexNow(message: message)
			}
			else {
				DispatchQueue.background(background: {
					self.addToIndexNow(message: message)
				})
			}
			
		}
	}
	
	func addToIndexNow(message: MsgMessage) {
		let topic = message.topic.nameQualified
		let payload = topic + " " + message.payload.dataString
		
		do {
			try self.inMemoryDBQueue.write { db in
				try db.execute(sql: "DELETE FROM message WHERE topic = :topic",
							   arguments: ["topic": topic])
			}
			
			try self.inMemoryDBQueue.write { db in
				try Message(topic: topic, payload: payload).insert(db)
			}
		}
		catch {
			NSLog("Error adding message to index \(error)")
		}
	}
	
	func clear(topicStartsWith topic: String) {
		do {
			try inMemoryDBQueue.write { db in
				try db.execute(sql: "DELETE FROM message WHERE topic LIKE :topic",
							   arguments: ["topic": "\(topic)%"])
			}
		}
		catch {
			NSLog("Error adding message to index \(error)")
		}
	}
	
	func search(text: String, topic: String = "") -> [String] {
		var result: [String] = []
		do {
			try inMemoryDBQueue.read { db in
				let topics = try String.fetchAll(db,
					  sql: "SELECT topic FROM message WHERE topic like ? AND payload MATCH ? ORDER by topic",
					  arguments: [
						"\(topic)%",
						text
					  ]
				)
				result.append(contentsOf: topics)
			}
		}
		catch {
			NSLog("Error executing search", error.localizedDescription)
		}
		
		return result
	}
	
}
