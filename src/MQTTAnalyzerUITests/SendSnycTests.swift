//
//  SensSnycTest.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 20.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import CocoaMQTT

private let clientID = "ClientForUnitTesting-"

private let host = "localhost"
private let port: UInt16 = 1883
private let delegate_queue_key = DispatchSpecificKey<String>()
private let delegate_queue_val = "_custom_delegate_queue_"

class SendSnycTests: XCTestCase {
	var deleQueue: DispatchQueue!
	
	override func setUp() {
		deleQueue = DispatchQueue(label: "cttest")
		deleQueue.setSpecific(key: delegate_queue_key, value: delegate_queue_val)
		super.setUp()
	}
	
	func testConnect() {
		let caller = Caller()
		let mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
		mqtt.delegateQueue = deleQueue
		mqtt.delegate = caller
		mqtt.logLevel = .debug
		mqtt.autoReconnect = false
 
		_ = mqtt.connect()
		
		XCTAssertTrue(wait(for: { caller.isConnected }))

		let topics = ["t/0", "t/1", "t/2"]

		mqtt.publish(topics[0], withString: "0", qos: .qos0, retained: false)
		mqtt.publish(topics[1], withString: "1", qos: .qos1, retained: false)
		mqtt.publish(topics[2], withString: "2", qos: .qos2, retained: false)
		
		XCTAssertTrue(wait(for: {
			if caller.sents.count >= 3 {
				return true
			}
			return false
		}))

		mqtt.disconnect()
		
		XCTAssertTrue(wait(for: {
			caller.isConnected == false
		}))
		
		XCTAssertEqual(mqtt.connState, .disconnected)
	}
	
    func testExample() throws {
		let client = MQTTCLient(
			broker: Broker(
				alias: "1883",
				hostname: "192.168.3.15",
				port: 1883
			),
			credentials: nil
		)
		let semaphore = DispatchSemaphore(value: 0)
		
		DispatchQueue.main.async {
			client.client.didConnectAck = { (mqtt: CocoaMQTT, ack: CocoaMQTTConnAck) in
				if ack == .accept {
					print("connected")
					
					client.client.didPublishMessage = { (mqtt: CocoaMQTT, msg: CocoaMQTTMessage, id: UInt16) in
						print(id)
						semaphore.signal()
					}
					let msgId = client.publish("test", "test from siri")
				}
			}
		}
		
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
}

private class Caller: CocoaMQTTDelegate {
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
