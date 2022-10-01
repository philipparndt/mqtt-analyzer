//
//  CocoaMQTTRegression.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-25.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest
import CocoaMQTT

class CocoaMQTTRegressionTests: XCTestCase {
	func testDecodeBinary789c8d() {
		UserDefaults().set("3.1.1", forKey: "cocoamqtt_mqtt_version")
		
		let publish = MqttDecodePublish()
		publish.decodePublish(fixedHeader: 49, publishData:
								[0, 4, 116, 101, 115, 116,
								 0x78, 0x9C, 0x8D])
	}
}
