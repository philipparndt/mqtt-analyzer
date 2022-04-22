//
//  IntentHandler.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 20.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Intents
import SwiftUI
import CocoaMQTT

class IntentHandler: INExtension, PublishMQTTMessageIntentHandling, ReceiveMQTTMessageIntentHandling {
	    
    override func handler(for intent: INIntent) -> Any {
		if intent is PublishMQTTMessageIntent {
			return self
		}
		else if intent is ReceiveMQTTMessageIntent {
			return self
		}

		fatalError("Unhandled Intent error : \(intent)")
    }
	
	func transformQos(qos: Qos) -> Int {
		switch qos {
		case .qos1:
			return 1
		case .qos2:
			return 2
		default:
			return 0
		}
	}
	
	func handle(intent: PublishMQTTMessageIntent, completion: @escaping (PublishMQTTMessageIntentResponse) -> Void) {
		
		if let broker = intent.broker,
			let topic = intent.topic,
			let message = intent.message,
		    let retain = intent.retainMessage as? Bool {
			
			let sqlite = SQLitePersistence()
			let firstHost = sqlite.first(byName: broker)
			sqlite.close()

			if let host = firstHost {
				do {
					let result = try PublishSync.publish(
						host: host,
						topic: topic.trimmingCharacters(in: [" "]),
						message: message,
						retain: retain,
						qos: transformQos(qos: intent.qos)
					)

					completion(response(from: result ? nil : "Publish failed"))
				}
				catch {
					completion(response(from: "\(error)"))
				}
			}

			completion(response(from: "Error finding broker"))
		}
	}
	
	func response(from error: String?) -> PublishMQTTMessageIntentResponse {
		let response = PublishMQTTMessageIntentResponse(
			code: error == nil ? .success : .failure,
			userActivity: nil)
		
		response.error = error
		
		return response
	}
	
	func resolveTopic(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		   
	   if let topic = intent.topic {
		   completion(INStringResolutionResult.success(with: topic))
	   } else {
		   completion(INStringResolutionResult.needsValue())
	   }
   }
   
   func resolveMessage(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
	   if let message = intent.message {
		   completion(INStringResolutionResult.success(with: message))
	   } else {
		   completion(INStringResolutionResult.needsValue())
	   }
   }
	
	func resolveBroker(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let broker = intent.broker {
			completion(INStringResolutionResult.success(with: broker))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
	
	func resolveRetain(for intent: PublishMQTTMessageIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		if let retain = intent.retainMessage as? Bool {
			completion(INBooleanResolutionResult.success(with: retain))
		} else {
			completion(INBooleanResolutionResult.needsValue())
		}
	}
	
	func load() -> [NSString] {
		let sqlite = SQLitePersistence()
		let brokers = sqlite.allNames()
		sqlite.close()
		
		return brokers
			.map { $0 as NSString }
	}
	
	func provideBrokerOptionsCollection(for intent: PublishMQTTMessageIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		completion(INObjectCollection(items: load()), nil)
	}
	
	// MARK: Receive
	
	func provideBrokerOptionsCollection(for intent: ReceiveMQTTMessageIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
			completion(INObjectCollection(items: load()), nil)
	}
	
	func handle(intent: ReceiveMQTTMessageIntent, completion: @escaping (ReceiveMQTTMessageIntentResponse) -> Void) {
		
		if let broker = intent.broker,
			let topic = intent.topic,
		    let timeout = intent.timeoutSeconds {
			
			let sqlite = SQLitePersistence()
			let firstHost = sqlite.first(byName: broker)
			sqlite.close()

			if let host = firstHost {
				do {
					let result = try PublishSync.receiveFirst(
						host: host,
						topic: topic.trimmingCharacters(in: [" "]),
						timeout: Int(truncating: timeout)
					)
					
					let response = ReceiveMQTTMessageIntentResponse(
						code: result != nil ? .success : .failure,
						userActivity: nil)
					response.message = result
					
					completion(response)
				}
				catch {
				}
			}

			completion(ReceiveMQTTMessageIntentResponse(
				code: .failure,
					  userActivity: nil))
		}
	}
}
