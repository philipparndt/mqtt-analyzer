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
		client.publish(topic, payload
						.replacingOccurrences(of: "\t", with: "")
						.replacingOccurrences(of: "\n", with: ""))
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
"""
{
	"battery": 97,
	"humidity": 37.17,
	"linkquality": 31,
	"pressure": 962,
	"temperature": 22.58,
	"voltage": 2995
}
""")
		
		publish("home/contacts/frontdoor",
"""
{
	"battery": 91,
	"contact": true,
	"linkquality": 65,
	"voltage": 2985
}
""")

		publish("home/dishwasher/000123456789",
"""
{
	"phase": "DRYING",
	"phaseId": 1799,
	"remainingDuration": "0:38",
	"remainingDurationMinutes": 38,
	"state": "RUNNING",
	"timeCompleted": "10:20"
}
""")
		
		publish("home/dishwasher/000123456789/full",
"""
{
	"ident": {
		"deviceIdentLabel": {
			"fabIndex": "64",
			"fabNumber": "000123456789",
			"matNumber": "10999999",
			"swids": [
				"1",
				"2",
				"3",
				"4",
				"5",
				"6",
				"7",
				"8",
				"9",
				"10",
				"11"
			],
			"techType": "G7560"
		},
		"deviceName": "",
		"type": {
			"key_localized": "Devicetype",
			"value_localized": "Dishwasher",
			"value_raw": 7
		},
		"xkmIdentLabel": {
			"releaseVersion": "03.59",
			"techType": "EK037"
		}
	},
	"state": {
		"ProgramID": {
			"key_localized": "Program Id",
			"value_localized": "",
			"value_raw": 6
		},
		"dryingStep": {
			"key_localized": "Drying level",
			"value_localized": "",
			"value_raw": null
		},
		"elapsedTime": [
			0,
			0
		],
		"light": 2,
		"plateStep": [],
		"programPhase": {
			"key_localized": "Phase",
			"value_localized": "Drying",
			"value_raw": 1799
		},
		"programType": {
			"key_localized": "Program type",
			"value_localized": "Operation mode",
			"value_raw": 0
		},
		"remainingTime": [
			0,
			38
		],
		"remoteEnable": {
			"fullRemoteControl": true,
			"smartGrid": false
		},
		"signalDoor": false,
		"signalFailure": false,
		"signalInfo": false,
		"spinningSpeed": {
			"key_localized": "Spinning Speed",
			"unit": "rpm",
			"value_localized": null,
			"value_raw": null
		},
		"startTime": [
			0,
			0
		],
		"status": {
			"key_localized": "State",
			"value_localized": "In use",
			"value_raw": 5
		},
		"targetTemperature": [
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			},
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			},
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			}
		],
		"temperature": [
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			},
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			},
			{
				"unit": "Celsius",
				"value_localized": null,
				"value_raw": -32768
			}
		],
		"ventilationStep": {
			"key_localized": "Power Level",
			"value_localized": "",
			"value_raw": null
		}
	}
}
""")
	}
}
