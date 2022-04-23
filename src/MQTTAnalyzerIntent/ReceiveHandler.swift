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
					let result = try MQTTClientSync.receiveFirst(
						host: broker,
						topic: topic.trimmingCharacters(in: [" "]),
						timeout: Int(truncating: timeout)
					)
					
					completion(response(from: result))
				}
				catch {
					NSLog("Error during receive \(error)")
					completion(ReceiveMQTTMessageIntentResponse(
						code: .failure,
							  userActivity: nil))
				}
			}
			else {
				completion(ReceiveMQTTMessageIntentResponse(
					code: .failure,
						  userActivity: nil))
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
}
