//
//  PublishSync.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

enum MQTTError: String, Error {
	case connectionError = "Timeout during connection"
	case messageTimeout = "Message timeout"
}

class MQTTClientSync {
	class func createQueue() -> DispatchQueue {
		let queue = DispatchQueue(label: "syncPublishDelegateQueue")
		queue.setSpecific(
			key: DispatchSpecificKey<String>(),
			value: "syncPublishDelegateQueue"
		)
		return queue
	}
	
	class func transformQos(qos: Int) -> CocoaMQTTQoS {
		switch qos {
		case 1:
			return .qos1
		case 2:
			return .qos2
		default:
			return .qos0
		}
	}
	
	class func connect(host: Host, delegate: SyncMQTTDelegate) throws -> CocoaMQTT {
		let model = TopicTree()
		let client = MQTTClientCocoaMQTT(host: host, model: model)
		
		let mqtt = client.createClient(host: host)
		try client.configureClient(client: mqtt)
		
		mqtt.delegate = delegate
		let queue = createQueue()
		mqtt.delegateQueue = queue
				
		_ = mqtt.connect()
		
		if !wait(for: { delegate.connected }) {
			throw MQTTError.connectionError
		}
		
		return mqtt
	}
	
	class func publish(host: Host, topic: String, message: String, retain: Bool, qos: Int) throws -> Bool {
		let delegate = SyncMQTTDelegate()
		let mqtt = try connect(host: host, delegate: delegate)
		
		mqtt.publish(
			topic,
			withString: message,
			qos: transformQos(qos: qos),
			retained: retain
		)
		
		if !wait(for: { delegate.sents.count >= 1 }) {
			return false
		}
		
		mqtt.disconnect()
		
		if !wait(for: { !delegate.connected }) {
			return false
		}
		
		return true
	}
	
	class func receiveFirst(host: Host, topic: String, timeout: Int) throws -> String? {
		let delegate = SyncMQTTDelegate()
		let mqtt = try connect(host: host, delegate: delegate)
		mqtt.subscribe(topic)
		
		if !wait(for: { delegate.messages.count >= 1 }) {
			throw MQTTError.messageTimeout
		}
		
		return delegate.messages.first?.dataString
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
