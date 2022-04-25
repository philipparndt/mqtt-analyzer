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

class IntentHandler: INExtension {
	    
    override func handler(for intent: INIntent) -> Any {
		if intent is PublishMQTTMessageIntent {
			return PublishHandler()
		}
		else if intent is ReceiveMQTTMessageIntent {
			return ReceiveHandler()
		}
		else if intent is RequestResponseIntent {
			return RequestResponseHandler()
		}
		
		fatalError("Unhandled Intent error : \(intent)")
    }
	
}
