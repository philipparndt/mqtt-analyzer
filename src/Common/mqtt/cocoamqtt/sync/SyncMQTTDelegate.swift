//
//  SyncMQTTDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 23.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

class SyncMQTTDelegate: CocoaMQTTDelegate {
	private let semaphore = DispatchSemaphore(value: 1)
	
	private var pMessages = [MsgPayload]()
	
	private var pSents = [UInt16]()
	
	private var pConnected = false
	
	var connected: Bool {
		var result: Bool
		semaphore.wait()
		result = pConnected
		semaphore.signal()
		return result
	}
	
	var messages: [MsgPayload] {
		var result: [MsgPayload]
		semaphore.wait()
		result = pMessages
		semaphore.signal()
		return result
	}
	
	var sents: [UInt16] {
		var result: [UInt16]
		semaphore.wait()
		result = pSents
		semaphore.signal()
		return result
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		semaphore.wait()
		pConnected = ack == .accept
		semaphore.signal()
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		semaphore.wait()
		pSents.append(id)
		semaphore.signal()
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		semaphore.wait()
		pMessages.append(MsgPayload(data: message.payload))
		semaphore.signal()
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
		semaphore.wait()
		pConnected = false
		semaphore.signal()
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}
}
