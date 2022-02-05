//
//  ExampleMessages.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT
import XCTest

func randomClientId() -> String {
	return "mqtt-analyzer-\(String.random(length: 8))"
}

class MQTTCLient {
	let client: CocoaMQTT
	
	init(hostname: String) {
		client = MQTTCLient.connect(hostname: hostname)
	}
	
	class func connect(hostname: String) -> CocoaMQTT {
		let result = CocoaMQTT(clientID: randomClientId(),
							  host: hostname,
							  port: 1883)
		result.keepAlive = 60
		result.autoReconnect = false
		
		if !result.connect() {
			XCTFail("MQTT Connection failed")
		}

		return result
	}
	
	func publish(_ topic: String, _ payload: String) {
		client.publish(CocoaMQTTMessage(
			topic: topic,
			string: payload,
			qos: CocoaMQTTQoS.qos2,
			retained: true)
		)
	}
}

class ExampleMessages {
	let client: MQTTCLient
	init(hostname: String) {
		self.client = MQTTCLient(hostname: hostname)
	}
	
	func publish(_ topic: String, _ payload: String) {
		client.publish(topic, payload)
	}
	
	func publish() {
		publish("home/sensors/water", "{\"temperature\":50.5}")

		publish("hue/light/kitchen/coffee-spot",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":366}")
		publish("hue/light/kitchen/kitchen-1",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("hue/light/kitchen/kitchen-2",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("hue/light/kitchen/kitchen-3",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("hue/light/kitchen/kitchen-4",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("hue/light/kitchen/kitchen-5",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")

		publish("hue/light/office/left",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")
		publish("hue/light/office/center",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":233}")
		publish("hue/light/office/right",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")

		publish("home/sensors/air/in",
				"{\"temperature\":21.5625}")
		publish("home/sensors/air/out",
				"{\"temperature\":23.1875}")
		publish("home/sensors/bathroom/temperature",
				"{\"battery\":97,\"voltage\":2995,\"temperature\":22.58,\"humidity\":37.17,\"pressure\":962,\"linkquality\":31}")
	}
}
