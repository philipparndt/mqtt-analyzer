//
//  Persistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-06.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

protocol Persistence {
	func delete(_ host: Host)
	
	func load()
	
	func create(_ host: Host)
		
	func update(_ host: Host)
}

class PersistenceEncoder {
	static func encode(subscriptions: [TopicSubscription]) -> Data {
		do {
			return try JSONEncoder().encode(subscriptions)
		} catch {
			NSLog("Unexpected error encoding subscriptions: \(error).")
			return Data()
		}
	}
	
	static func decode(subscriptions: Data) -> [TopicSubscription] {
		do {
			if subscriptions.isEmpty {
				return []
			}
			
			return try JSONDecoder().decode([TopicSubscription].self, from: subscriptions)
		} catch {
			NSLog("Unexpected error decoding subscriptions: \(error).")
			NSLog("`\(String(data: subscriptions, encoding: .utf8)!)`")
			return [TopicSubscription(topic: "#", qos: 0)]
		}
	}
	
	static func encode(certificates: [CertificateFile]) -> Data {
		do {
			return try JSONEncoder().encode(certificates)
		} catch {
			NSLog("Unexpected error encoding certificate files: \(error).")
			return Data()
		}
	}
	
	static func decode(certificates: Data) -> [CertificateFile] {
		do {
			if certificates.isEmpty {
				return []
			}
			
			return try JSONDecoder().decode([CertificateFile].self, from: certificates)
		} catch {
			NSLog("Unexpected error decoding certificate files: \(error).")
			return []
		}
	}
}
