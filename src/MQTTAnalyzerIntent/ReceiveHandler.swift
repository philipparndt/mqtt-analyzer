//
//  ReceiveHandler.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Intents
import CocoaMQTT

class ReceiveHandler: INExtension, ReceiveMQTTMessageIntentHandling {
	
	func provideBrokerOptionsCollection(for intent: ReceiveMQTTMessageIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
			completion(INObjectCollection(items: loadBrokers()), nil)
	}
	
	func handle(intent: ReceiveMQTTMessageIntent, completion: @escaping (ReceiveMQTTMessageIntentResponse) -> Void) {
		
		if let brokerName = intent.broker,
			let topic = intent.topic,
			let timeout = intent.timeoutSeconds {

			if let broker = firstBroker(by: brokerName) {
				do {
					let host = Host(settings: broker)
					let result = try MQTTClientSync.receiveFirst(
						host: host,
						topic: topic.trimmingCharacters(in: [" "]),
						timeout: Int(truncating: timeout)
					)
					
					completion(response(from: result))
				} catch MQTTError.runtimeError(let errorMessage) {
					completion(fail(from: errorMessage))
				}
				catch {
					completion(fail(from: "Unexpected error during receive \(error)."))
				}
			}
			else {
				completion(fail(from: "Unknown broker."))
			}
		}
	}
		
	func response(from message: String?) -> ReceiveMQTTMessageIntentResponse {
		let response = ReceiveMQTTMessageIntentResponse(
			code: message != nil ? .success : .failure,
			userActivity: nil)
		response.message = message
		return response
	}
	
	func fail(from error: String?) -> ReceiveMQTTMessageIntentResponse {
		let response = ReceiveMQTTMessageIntentResponse(
			code: .failure,
			userActivity: nil)
		response.error = error
		return response
	}
}
