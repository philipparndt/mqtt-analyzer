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

class PublishSyncTests: XCTestCase {
	var deleQueue: DispatchQueue!
	
	override func setUp() {
		deleQueue = DispatchQueue(label: "cttest")
		deleQueue.setSpecific(key: delegate_queue_key, value: delegate_queue_val)
		super.setUp()
	}
	
	func testConnect() {
//		let caller = SyncMQTTDelegate()
//		let mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
//		mqtt.delegateQueue = deleQueue
//		mqtt.delegate = caller
//		mqtt.logLevel = .debug
//		mqtt.autoReconnect = false
//
//		_ = mqtt.connect()
//
//		XCTAssertTrue(MQTTAnalyzerUITests.wait(for: { caller.isConnected }))
//
//		let topics = ["t/0", "t/1", "t/2"]
//
//		mqtt.publish(topics[0], withString: "0", qos: .qos0, retained: false)
//		mqtt.publish(topics[1], withString: "1", qos: .qos1, retained: false)
//		mqtt.publish(topics[2], withString: "2", qos: .qos2, retained: false)
//
//		XCTAssertTrue(MQTTAnalyzerUITests.wait(for: {
//			if caller.sents.count >= 3 {
//				return true
//			}
//			return false
//		}))
//
//		mqtt.disconnect()
//
//		XCTAssertTrue(MQTTAnalyzerUITests.wait(for: {
//			caller.isConnected == false
//		}))
//
//		XCTAssertEqual(mqtt.connState, .disconnected)
	}
}
