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

class IntentHandler: INExtension, SendMQTTMessageIntentHandling, InitHost {
	func initHost(host: Host) {
		
	}
	    
    override func handler(for intent: INIntent) -> Any {
		guard intent is SendMQTTMessageIntent else {
			fatalError("Unhandled Intent error : \(intent)")
		}
		
        return self
    }
	
	func handle(intent: SendMQTTMessageIntent, completion: @escaping (SendMQTTMessageIntentResponse) -> Void) {
		
		if let broker = intent.broker,
			let topic = intent.topic,
			let message = intent.message {
			
			let sqlite = SQLitePersistence()
			let firstHost = sqlite.first(byName: broker)
			sqlite.close()

			if let host = firstHost {
				print("#### MQTTAnalyzer IntentHandler: \(host.hostname)")
				
				do {
					let result = try PublishSync.publish(
						host: host,
						topic: topic,
						message: message,
						retain: false
					)

					completion(response(from: result ? nil : "Publish failed"))
				}
				catch {
					print("#### MQTTAnalyzer IntentHandler: Error \(error)")
					completion(response(from: "\(error)"))
				}
			}
		}
	}
	
	func response(from error: String?) -> SendMQTTMessageIntentResponse {
		let response = SendMQTTMessageIntentResponse(
			code: error == nil ? .success : .failure,
			userActivity: nil)
		
		response.error = error
		
		return response
	}
	
	func resolveTopic(for intent: SendMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		   
	   if let topic = intent.topic {
		   completion(INStringResolutionResult.success(with: topic))
	   } else {
		   completion(INStringResolutionResult.needsValue())
	   }
   }
   
   func resolveMessage(for intent: SendMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
	   if let message = intent.message {
		   completion(INStringResolutionResult.success(with: message))
	   } else {
		   completion(INStringResolutionResult.needsValue())
	   }
   }
	
	func resolveBroker(for intent: SendMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let broker = intent.broker {
			completion(INStringResolutionResult.success(with: broker))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
	
}
