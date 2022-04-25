//
//  ReceiveHandler.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Intents
import CocoaMQTT

class RequestResponseHandler: INExtension, RequestResponseIntentHandling {
	func provideBrokerOptionsCollection(for intent: RequestResponseIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
		completion(INObjectCollection(items: loadBrokers()), nil)
	}
	
	func handle(intent: RequestResponseIntent, completion: @escaping (RequestResponseIntentResponse) -> Void) {
		if let brokerName = intent.broker,
		   let requestTopic = intent.requestTopic,
		   let requestPayload = intent.requestPayload,
		   let responseTopic = intent.responseTopic,
		   let timeout = intent.timeoutSeconds {
			
			if let broker = firstBroker(by: brokerName) {
				do {
					let result = try MQTTClientSync.requestResponse(
						host: broker,
						requestTopic: requestTopic,
						requestPayload: requestPayload,
						qos: transformQosToInt(qos: intent.qos),
						responseTopic: responseTopic,
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
		
	func response(from message: String?) -> RequestResponseIntentResponse {
		let response = RequestResponseIntentResponse(
			code: message != nil ? .success : .failure,
			userActivity: nil)
		response.message = message
		return response
	}
	
	func fail(from error: String?) -> RequestResponseIntentResponse {
		let response = RequestResponseIntentResponse(
			code: .failure,
			userActivity: nil)
		response.error = error
		return response
	}
}
