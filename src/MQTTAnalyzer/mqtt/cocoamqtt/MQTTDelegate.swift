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
		// currently not necessary, but required by protocol
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
		// currently not necessary, but required by protocol
	}
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
		// currently not necessary, but required by protocol
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		// currently not necessary, but required by protocol
	}
	
	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		// currently not necessary, but required by protocol
	}
}
