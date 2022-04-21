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

class IntentHandler: INExtension, PublishMQTTMessageIntentHandling, InitHost {

	func initHost(host: Host) {
		
	}
	    
    override func handler(for intent: INIntent) -> Any {
		guard intent is PublishMQTTMessageIntent else {
			fatalError("Unhandled Intent error : \(intent)")
		}
		
        return self
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
						topic: topic,
						message: message,
						retain: retain
					)

					completion(response(from: result ? nil : "Publish failed"))
				}
				catch {
					completion(response(from: "\(error)"))
				}
			}
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
	
}
