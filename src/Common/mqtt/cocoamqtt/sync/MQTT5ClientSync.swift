//
//  PublishSync.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

class MQTT5ClientSync {
	class func createQueue() -> DispatchQueue {
		let queue = DispatchQueue(label: "syncMQTT5DelegateQueue")
		queue.setSpecific(
			key: DispatchSpecificKey<String>(),
			value: "syncMQTT5DelegateQueue"
		)
		return queue
	}
	
	class func connect(host: Host) throws -> (CocoaMQTT5, SyncListener) {
		let model = TopicTree()
		let client = MQTT5ClientCocoaMQTT(host: host, model: model)
		let delegate = SyncMQTT5Delegate()

		let mqtt = client.createClient(host: host)
		try client.configureClient(client: mqtt)
		
		mqtt.delegate = delegate
		let queue = createQueue()
		mqtt.delegateQueue = queue
				
		_ = mqtt.connect()
		
		if !wait(for: { delegate.delegate.connected }) {
			throw connectionTimeoutError(host: host)
		}
		
		return (mqtt, delegate)
	}
		
	class func publish(host: Host, topic: String, message: String, retain: Bool, qos: Int) throws {
		let connected = try connect(host: host)
		let mqtt = connected.0
		let delegate = connected.1
		
		mqtt.publish(
			topic,
			withString: message,
			qos: transformQos(qos: qos),
			retained: retain,
			properties: MqttPublishProperties()
		)
		
		if !wait(for: { delegate.delegate.sents.count >= 1 }) {
			throw sentMessageTimeoutError(topic: topic)
		}
		
		mqtt.disconnect()
		
		if !wait(for: { !delegate.delegate.connected }) {
			throw disconnectionTimeoutError(host: host)
		}
	}
	
	class func receiveFirst(host: Host, topic: String, timeout: Int) throws -> String? {
		let connected = try connect(host: host)
		let mqtt = connected.0
		let delegate = connected.1
		mqtt.subscribe(topic)
		
		if !wait(for: { delegate.delegate.messages.count >= 1 }, timeout: timeout) {
			throw messageTimeoutError(topic: topic)
		}
		
		return delegate.delegate.messages.first?.dataString
	}
	
	class func requestResponse(host: Host, requestTopic: String, requestPayload: String, qos: Int,
							   responseTopic: String, timeout: Int) throws -> String? {
		let connected = try connect(host: host)
		let mqtt = connected.0
		let delegate = connected.1
		mqtt.subscribe(responseTopic)
		if !wait(for: { delegate.delegate.didSubscribe == 1 }) {
			throw subscriptionTimeoutError(topic: responseTopic)
		}
		
		let properties = MqttPublishProperties()
		properties.responseTopic = requestTopic
		
		mqtt.publish(
			requestTopic,
			withString: requestPayload,
			qos: transformQos(qos: qos),
			retained: false,
			properties: properties
		)
		
		if !wait(for: { delegate.delegate.messages.count >= 1 }, timeout: timeout) {
			throw messageTimeoutError(topic: responseTopic)
		}
		
		return delegate.delegate.messages.first?.dataString
	}
}
