//
//  PublishSync.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

enum MQTTError: Error {
	case runtimeError(String)
}

func subscriptionTimeoutError(topic: String) -> MQTTError {
	return MQTTError.runtimeError("Timeout waiting for subscribe on topic \(topic).")
}

func messageTimeoutError(topic: String) -> MQTTError {
	return MQTTError.runtimeError("Timeout waiting for message on topic \(topic). Maybe switch to retained messages.")
}

func connectionTimeoutError(host: Host) -> MQTTError {
	return MQTTError.runtimeError("Error connecting to broker \(host.hostname)")
}

func disconnectionTimeoutError(host: Host) -> MQTTError {
	return MQTTError.runtimeError("Error disconnecting from broker \(host.hostname)")
}

func sentMessageTimeoutError(topic: String) -> MQTTError {
	return MQTTError.runtimeError("Timout publishing message to topic \(topic)")
}

protocol SyncListener {
	var delegate: SyncDelegate { get }
}

func transformQos(qos: Int) -> CocoaMQTTQoS {
	switch qos {
	case 1:
		return .qos1
	case 2:
		return .qos2
	default:
		return .qos0
	}
}

class MQTTClientSync {
	class func publish(host: Host, topic: String, message: String, retain: Bool, qos: Int) throws {
		
		if host.protocolVersion == .mqtt5 {
			try MQTT5ClientSync.publish(
				host: host,
				topic: topic,
				message: message,
				retain: retain,
				qos: qos
			)
		}
		else {
			try MQTT3ClientSync.publish(
				host: host,
				topic: topic,
				message: message,
				retain: retain,
				qos: qos
			)
		}
	}
	
	class func receiveFirst(host: Host, topic: String, timeout: Int) throws -> String? {
		if host.protocolVersion == .mqtt5 {
			return try MQTT5ClientSync.receiveFirst(
				host: host,
				topic: topic,
				timeout: timeout
			)
		}
		else {
			return try MQTT3ClientSync.receiveFirst(
				host: host,
				topic: topic,
				timeout: timeout
			)
		}
	}
	
	class func requestResponse(host: Host, requestTopic: String, requestPayload: String, qos: Int, responseTopic: String, timeout: Int) throws -> String? {
		if host.protocolVersion == .mqtt5 {
			return try MQTT5ClientSync.requestResponse(
				host: host,
				requestTopic: requestTopic,
				requestPayload: requestPayload,
				qos: qos,
				responseTopic: responseTopic,
				timeout: timeout
			)
		}
		else {
			return try MQTT3ClientSync.requestResponse(
				host: host,
				requestTopic: requestTopic,
				requestPayload: requestPayload,
				qos: qos,
				responseTopic: responseTopic,
				timeout: timeout
			)
		}
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
