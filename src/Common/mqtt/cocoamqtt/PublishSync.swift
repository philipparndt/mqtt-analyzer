//
//  PublishSync.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

class PublishSync {
	class func createQueue() -> DispatchQueue {
		let queue = DispatchQueue(label: "syncPublishDelegateQueue")
		queue.setSpecific(
			key: DispatchSpecificKey<String>(),
			value: "syncPublishDelegateQueue"
		)
		return queue
	}
	
	class func publish(host: Host, topic: String, message: String, retain: Bool) throws -> Bool {
		
		let model = TopicTree()
		let client = MQTTClientCocoaMQTT(host: host, model: model)
		
		let mqtt = client.createClient(host: host)
		try client.configureClient(client: mqtt)
		
		let delegate = SyncMQTTDelegate()
		mqtt.delegate = delegate
		let queue = createQueue()
		mqtt.delegateQueue = queue
				
		_ = mqtt.connect()
		
		if !wait(for: { delegate.isConnected }) {
			return false
		}
		
		mqtt.publish(
			topic,
			withString: message,
			qos: .qos1,
			retained: retain
		)
		
		if !wait(for: { delegate.sents.count >= 1 }) {
			return false
		}
		
		mqtt.disconnect()
		
		if !wait(for: { !delegate.isConnected }) {
			return false
		}
		
		return true
	}
}

func wait(for expectation: @escaping () -> Bool, timeout seconds: Int = 10) -> Bool {
	let semaphore = DispatchSemaphore(value: 0)
	let thread = Thread {
		while true {
			sleep(1)
			guard expectation() else {
				continue
			}
			semaphore.signal()
			break
		}
	}
	thread.start()
	let result = semaphore.wait(timeout: DispatchTime.now()
		.advanced(by: .seconds(seconds)))
	thread.cancel()
	return result == .success
}

class SyncMQTTDelegate: CocoaMQTTDelegate {
	var recvs = [UInt16]()
	
	var sents = [UInt16]()
	
	var acks = [UInt16]()
	
	var subs = [String]()
	
	var isConnected = false
	
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		if ack == .accept { isConnected = true }
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		sents.append(id)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		acks.append(id)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		
		recvs.append(id)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
		subs = subs.filter { (e) -> Bool in
			!topics.contains(e)
		}
	}
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
	}
	
	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		isConnected = false
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}
}
