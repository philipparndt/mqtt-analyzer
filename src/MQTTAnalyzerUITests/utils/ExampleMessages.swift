//
//  ExampleMessages.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import UIKit
import CocoaMQTT
import CocoaMQTTWebSocket
import XCTest

func randomClientId() -> String {
	return "mqtt-analyzer-\(String.random(length: 8))"
}

// MARK: - Logo Loading Helpers

enum LogoLoader {
	static func loadAppLogo(from bundle: Bundle) -> [UInt8]? {
		// First try: Load TestLogo.png from the UI test bundle (most reliable)
		if let logoPath = bundle.path(forResource: "TestLogo", ofType: "png"),
		   let data = try? Data(contentsOf: URL(fileURLWithPath: logoPath)) {
			return [UInt8](data)
		}

		// Second try: Load directly from the main app's asset catalog
		if let image = UIImage(named: "AppIcon"),
		   let pngData = image.pngData() {
			return [UInt8](pngData)
		}

		// Third try: Access the app bundle directly
		if let appBundle = Bundle(identifier: "de.rnd7.MQTTAnalyzer"),
		   let iconPath = appBundle.path(forResource: "AppIcon60x60@2x", ofType: "png"),
		   let data = try? Data(contentsOf: URL(fileURLWithPath: iconPath)) {
			return [UInt8](data)
		}

		// Fourth try: Walk up from the test bundle to find the project
		if let logoData = loadLogoFromSourceTree(bundle: bundle) {
			return logoData
		}

		// Final fallback: generate a test image that looks like a logo
		return generateLogoImage()
	}

	static func loadLogoFromSourceTree(bundle: Bundle) -> [UInt8]? {
		var searchPath = bundle.bundleURL

		for _ in 0..<15 {
			let assetPath = searchPath
				.appendingPathComponent("src/MQTTAnalyzer/Assets.xcassets/AppIcon.appiconset/App-Store-iOS.png")
			if FileManager.default.fileExists(atPath: assetPath.path),
			   let data = try? Data(contentsOf: assetPath) {
				return [UInt8](data)
			}

			let altPath = searchPath
				.appendingPathComponent("MQTTAnalyzer/Assets.xcassets/AppIcon.appiconset/App-Store-iOS.png")
			if FileManager.default.fileExists(atPath: altPath.path),
			   let data = try? Data(contentsOf: altPath) {
				return [UInt8](data)
			}

			searchPath = searchPath.deletingLastPathComponent()
		}

		return nil
	}

	static func generateLogoImage() -> [UInt8] {
		let size = CGSize(width: 128, height: 128)
		UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
		defer { UIGraphicsEndImageContext() }

		guard let context = UIGraphicsGetCurrentContext() else {
			return createMinimalPNG()
		}

		let rect = CGRect(origin: .zero, size: size)
		let cornerRadius: CGFloat = 28
		let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

		context.saveGState()
		path.addClip()

		let colors = [
			UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor,
			UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0).cgColor
		]
		if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
									 colors: colors as CFArray, locations: nil) {
			context.drawLinearGradient(gradient, start: .zero,
									   end: CGPoint(x: 0, y: size.height), options: [])
		}
		context.restoreGState()

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		let attrs: [NSAttributedString.Key: Any] = [
			.font: UIFont.boldSystemFont(ofSize: 72),
			.foregroundColor: UIColor.white,
			.paragraphStyle: paragraphStyle
		]
		"M".draw(in: CGRect(x: 0, y: 28, width: size.width, height: size.height), withAttributes: attrs)

		guard let image = UIGraphicsGetImageFromCurrentImageContext(),
			  let pngData = image.pngData() else {
			return createMinimalPNG()
		}

		return [UInt8](pngData)
	}

	static func createMinimalPNG() -> [UInt8] {
		let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		let ihdr: [UInt8] = [
			0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
			0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
			0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE
		]
		let idat: [UInt8] = [
			0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
			0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00,
			0x00, 0x03, 0x00, 0x01
		]
		let iend: [UInt8] = [
			0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
			0xAE, 0x42, 0x60, 0x82
		]
		return pngHeader + ihdr + idat + iend
	}
}

class MQTTCLient {
	let client: CocoaMQTT

	init(broker: Broker, credentials: Credentials?) {
		client = MQTTCLient.connect(broker: broker, credentials: credentials)
	}

	class func createClient(broker: Broker) -> CocoaMQTT {
		let host = broker.hostname ?? "localhost"
		let port = broker.port ?? 1883
		let clientId = randomClientId()

		if broker.connectionProtocol == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: "")
			return CocoaMQTT(clientID: clientId,
								  host: host,
								  port: port,
								  socket: websocket)

		}
		else {
			return CocoaMQTT(clientID: clientId,
										  host: host,
										  port: port)
		}
	}

	class func connect(broker: Broker, credentials: Credentials?) -> CocoaMQTT {
		let result = createClient(broker: broker)

		if let tls = broker.tls {
			result.enableSSL = tls
		}

		result.username = broker.username ?? credentials?.username
		result.password = broker.password ?? credentials?.password

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
			retained: false)
		)
	}

	func publish(_ topic: String, data: [UInt8]) {
		client.publish(CocoaMQTTMessage(
			topic: topic,
			payload: data,
			qos: CocoaMQTTQoS.qos2,
			retained: false)
		)
	}
}

class ExampleMessages {
	let client: MQTTCLient
	init(broker: Broker, credentials: Credentials? = nil) {
		self.client = MQTTCLient(broker: broker, credentials: credentials)
	}

	func publish(_ topic: String, _ payload: String) {
		client.publish(topic, payload
						.replacingOccurrences(of: "\t", with: "")
						.replacingOccurrences(of: "\n", with: ""))
	}

	func publish(_ topic: String, data: [UInt8]) {
		client.publish(topic, data: data)
	}

	/// Publishes binary test messages including the app logo as PNG
	func publishBinary(prefix: String) {
		// Publish the MQTTAnalyzer logo as PNG image
		let testBundle = Bundle(for: type(of: self))
		if let logoData = LogoLoader.loadAppLogo(from: testBundle) {
			publish("\(prefix)test/binary/logo", data: logoData)
		}

		// Publish random binary data (256 bytes)
		var binaryData = [UInt8](repeating: 0, count: 256)
		for i in 0..<256 {
			binaryData[i] = UInt8.random(in: 0...255)
		}
		publish("\(prefix)test/binary/raw", data: binaryData)
	}

	func publish(prefix: String) {
		publish("\(prefix)home/sensors/water", "{\"temperature\":50.5}")

		publish("\(prefix)hue/light/kitchen/coffee-spot",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)hue/light/kitchen/kitchen-1",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)hue/light/kitchen/kitchen-2",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)hue/light/kitchen/kitchen-3",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)hue/light/kitchen/kitchen-4",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)hue/light/kitchen/kitchen-5",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")

		publish("\(prefix)hue/light/office/left",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")
		publish("\(prefix)hue/light/office/center",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":233}")
		publish("\(prefix)hue/light/office/right",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")

		publish("\(prefix)home/sensors/air/in",
				"{\"temperature\":21.5625}")
		publish("\(prefix)home/sensors/air/out",
				"{\"temperature\":23.1875}")
		publish("\(prefix)home/sensors/bathroom/temperature",
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
		
		publish("\(prefix)home/contacts/frontdoor",
"""
{
	"battery": 91,
	"contact": true,
	"linkquality": 65,
	"voltage": 2985
}
""")

		publish("\(prefix)home/dishwasher/000123456789",
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
		
		publish("\(prefix)home/dishwasher/000123456789/full",
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
	
	func disconnect() {
		self.client.client.disconnect()
	}
}
