//
//  MqttClient.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

enum MQTTConnectionState {
	case disconnected
	case connecting
	case connected
}

struct ConnectionState {
	static var sessionNum = 0

	var message: String?
	var state: MQTTConnectionState = .disconnected
}

class MsgSubject<T> {
	let subject = PassthroughSubject<T, Never>()
	var cancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	
	func send(_ message: T) {
		subject.send(message)
	}
	
	func cancel() {
		cancellable?.cancel()
	}
	
	func disconnected() {
		cancel()
		cancellable = nil
	}
}

protocol MqttClient {

	var host: Host { get }
	var connectionAlive: Bool { get }
	var connectionState: ConnectionState { get }
	
	func connect()
	
	func disconnect()
	
	func publish(message: Message)
}
