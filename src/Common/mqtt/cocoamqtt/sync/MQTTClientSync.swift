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

protocol SyncListener {
	var connected: Bool { get }
	
	var messages: [MsgPayload] { get }
	
	var sents: [UInt16] { get }
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
	class func publish(host: Host, topic: String, message: String, retain: Bool, qos: Int) throws -> Bool {
		
		if host.protocolVersion == .mqtt5 {
			return try MQTT5ClientSync.publish(
				host: host,
				topic: topic,
				message: message,
				retain: retain,
				qos: qos
			)
		}
		else {
			return try MQTT3ClientSync.publish(
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
