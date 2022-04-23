//
//  PushHandler.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Intents
import CocoaMQTT

class PublishHandler: INExtension, PublishMQTTMessageIntentHandling {
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
		
		if let brokerName = intent.broker,
			let topic = intent.topic,
			let message = intent.message,
			let retain = intent.retainMessage as? Bool {

			if let broker = firstBroker(by: brokerName) {
				do {
					let result = try MQTTClientSync.publish(
						host: broker,
						topic: topic.trimmingCharacters(in: [" "]),
						message: message,
						retain: retain,
						qos: transformQos(qos: intent.qos)
					)

					completion(response(from: result ? nil : "Publish failed"))
				}
				catch {
					NSLog("Error during publish \(error)")
					completion(response(from: "\(error)"))
				}
			}
			else {
				completion(response(from: "Error finding broker"))
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
	
	func provideBrokerOptionsCollection(for intent: PublishMQTTMessageIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		completion(INObjectCollection(items: loadBrokers()), nil)
	}
	
	func resolveTopic(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		resolve(string: intent.topic, with: completion)
   }
   
   func resolveMessage(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
	   resolve(string: intent.message, with: completion)
   }
	
	func resolveBroker(for intent: PublishMQTTMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		resolve(string: intent.broker, with: completion)
	}
	
	func resolveRetain(for intent: PublishMQTTMessageIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		resolve(boolean: intent.retainMessage, with: completion)
	}
}

extension PublishHandler {
	func resolve(string value: String?, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let val = value {
			completion(INStringResolutionResult.success(with: val))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
	
	func resolve(boolean value: NSNumber?, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		if let val = value as? Bool {
			completion(INBooleanResolutionResult.success(with: val))
		} else {
			completion(INBooleanResolutionResult.needsValue())
		}
	}
}
