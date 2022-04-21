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

class IntentHandler: INExtension, SendMQTTMessageIntentHandling {
    
    override func handler(for intent: INIntent) -> Any {
		guard intent is SendMQTTMessageIntent else {
			fatalError("Unhandled Intent error : \(intent)")
		}
		
        return self
    }
	
	func handle(intent: SendMQTTMessageIntent, completion: @escaping (SendMQTTMessageIntentResponse) -> Void) {
		
		if let broker = intent.broker, let topic = intent.topic, let message = intent.message {
			
			let client = MQTTCLient(
				broker: Broker(
					alias: "1883",
					hostname: "192.168.3.15",
					port: 1883
				),
				credentials: nil
			)
			
			client.client.didPublishMessage = { (mqtt: CocoaMQTT, msg: CocoaMQTTMessage, id: UInt16) in
				
				completion(SendMQTTMessageIntentResponse(
					code: SendMQTTMessageIntentResponseCode.success,
					userActivity: nil)
				)
			}
			let msgId = client.publish("test", "test from siri")
			// (CocoaMQTT, CocoaMQTTMessage, UInt16)
		}
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
