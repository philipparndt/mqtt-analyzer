//
//  PublishSync.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

class MQTT3ClientSync {
	class func createQueue() -> DispatchQueue {
		let queue = DispatchQueue(label: "syncPublishDelegateQueue")
		queue.setSpecific(
			key: DispatchSpecificKey<String>(),
			value: "syncPublishDelegateQueue"
		)
		return queue
	}
	
	class func connect(host: Host) throws -> (CocoaMQTT, SyncListener) {
		let model = TopicTree()
		let client = MQTTClientCocoaMQTT(host: host, model: model)
		let delegate = SyncMQTTDelegate()

		let mqtt = client.createClient(host: host)
		try client.configureClient(client: mqtt)
		
		mqtt.delegate = delegate
		let queue = createQueue()
		mqtt.delegateQueue = queue
				
		_ = mqtt.connect()
		
		if !wait(for: { delegate.connected }) {
			throw MQTTError.connectionError
		}
		
		return (mqtt, delegate)
	}
		
	class func publish(host: Host, topic: String, message: String, retain: Bool, qos: Int) throws -> Bool {
		let connected = try connect(host: host)
		let mqtt = connected.0
		let delegate = connected.1
		
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
		let connected = try connect(host: host)
		let mqtt = connected.0
		let delegate = connected.1
		mqtt.subscribe(topic)
		
		if !wait(for: { delegate.messages.count >= 1 }) {
			throw MQTTError.messageTimeout
		}
		
		return delegate.messages.first?.dataString
	}
}
