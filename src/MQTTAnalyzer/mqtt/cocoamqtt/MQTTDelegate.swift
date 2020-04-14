//
//  MQTTDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

class MQTTDelegate: CocoaMQTTDelegate {
	
	func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
		
	}
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
		
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		
	}
	
	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		
	}
}
