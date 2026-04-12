//
//  ExampleMessages.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import XCTest

// MARK: - Logo Loading Helpers

enum LogoLoader {
	static func loadAppLogo(from bundle: Bundle) -> Data? {
		// First try: Load TestLogo.png from the UI test bundle (most reliable)
		if let logoPath = bundle.path(forResource: "TestLogo", ofType: "png"),
		   let data = try? Data(contentsOf: URL(fileURLWithPath: logoPath)) {
			return data
		}

		#if canImport(UIKit)
		// Second try: Load directly from the main app's asset catalog
		if let image = UIImage(named: "AppIcon"),
		   let pngData = image.pngData() {
			return pngData
		}
		#elseif canImport(AppKit)
		if let image = NSImage(named: "AppIcon"),
		   let tiffData = image.tiffRepresentation,
		   let bitmap = NSBitmapImageRep(data: tiffData),
		   let pngData = bitmap.representation(using: .png, properties: [:]) {
			return pngData
		}
		#endif

		// Third try: Access the app bundle directly
		if let appBundle = Bundle(identifier: "de.rnd7.MQTTAnalyzer"),
		   let iconPath = appBundle.path(forResource: "AppIcon60x60@2x", ofType: "png"),
		   let data = try? Data(contentsOf: URL(fileURLWithPath: iconPath)) {
			return data
		}

		// Fourth try: Walk up from the test bundle to find the project
		if let logoData = loadLogoFromSourceTree(bundle: bundle) {
			return logoData
		}

		// Final fallback: generate a test image that looks like a logo
		return generateLogoImage()
	}

	static func loadLogoFromSourceTree(bundle: Bundle) -> Data? {
		var searchPath = bundle.bundleURL

		for _ in 0..<15 {
			let assetPath = searchPath
				.appendingPathComponent("src/MQTTAnalyzer/Assets.xcassets/AppIcon.appiconset/App-Store-iOS.png")
			if FileManager.default.fileExists(atPath: assetPath.path),
			   let data = try? Data(contentsOf: assetPath) {
				return data
			}

			let altPath = searchPath
				.appendingPathComponent("MQTTAnalyzer/Assets.xcassets/AppIcon.appiconset/App-Store-iOS.png")
			if FileManager.default.fileExists(atPath: altPath.path),
			   let data = try? Data(contentsOf: altPath) {
				return data
			}

			searchPath = searchPath.deletingLastPathComponent()
		}

		return nil
	}

	static func generateLogoImage() -> Data {
		let size = CGSize(width: 128, height: 128)

		#if canImport(UIKit)
		UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
		defer { UIGraphicsEndImageContext() }

		guard let context = UIGraphicsGetCurrentContext() else {
			return Data(createMinimalPNG())
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
			return Data(createMinimalPNG())
		}

		return pngData
		#elseif canImport(AppKit)
		let image = NSImage(size: size)
		image.lockFocus()

		guard let context = NSGraphicsContext.current?.cgContext else {
			image.unlockFocus()
			return Data(createMinimalPNG())
		}

		let rect = CGRect(origin: .zero, size: size)
		let cornerRadius: CGFloat = 28
		let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

		context.saveGState()
		path.addClip()

		let colors = [
			NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor,
			NSColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0).cgColor
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
			.font: NSFont.boldSystemFont(ofSize: 72),
			.foregroundColor: NSColor.white,
			.paragraphStyle: paragraphStyle
		]
		"M".draw(in: CGRect(x: 0, y: 28, width: size.width, height: size.height), withAttributes: attrs)

		image.unlockFocus()

		guard let tiffData = image.tiffRepresentation,
			  let bitmap = NSBitmapImageRep(data: tiffData),
			  let pngData = bitmap.representation(using: .png, properties: [:]) else {
			return Data(createMinimalPNG())
		}

		return pngData
		#endif
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

// MARK: - CLI-based MQTT Publisher

class ExampleMessages {
	private let brokerFilePath: String
	private let cliBinaryPath: String

	init(broker: Broker, credentials: Credentials? = nil) {
		// Create temporary .mqttbroker file
		let brokerJSON: [String: Any] = [
			"version": 1,
			"broker": [
				"alias": "UI Test Broker",
				"hostname": broker.hostname ?? "localhost",
				"port": Int(broker.port ?? 1883),
				"protocolMethod": broker.connectionProtocol == .websocket ? "websocket" : "mqtt",
				"protocolVersion": broker.protocolVersion == .mqtt5 ? "mqtt5" : "mqtt3",
				"basePath": "",
				"ssl": broker.tls ?? false,
				"untrustedSSL": false,
				"authType": ExampleMessages.authTypeString(broker.authType),
				"username": broker.username ?? credentials?.username as Any,
				"password": broker.password ?? credentials?.password as Any,
				"subscriptions": [["topic": "#", "qos": 0]],
				"limitTopic": 0,
				"limitMessagesBatch": 500
			]
		]

		guard let data = try? JSONSerialization.data(withJSONObject: brokerJSON, options: .prettyPrinted) else {
			fatalError("[ExampleMessages] Failed to serialize broker JSON")
		}
		let path = NSTemporaryDirectory() + "uitest-\(UUID().uuidString).mqttbroker"
		FileManager.default.createFile(atPath: path, contents: data)
		self.brokerFilePath = path

		// Find CLI binary in the build products directory.
		// Test bundle is at: .../Build/Products/Debug/MQTTAnalyzerUITests-Runner.app/Contents/PlugIns/MQTTAnalyzerUITests.xctest
		// CLI binary is at:  .../Build/Products/Debug/mqtt-analyzer
		// So we walk up from the test bundle to the products directory.
		let testBundle = Bundle(for: type(of: self))
		self.cliBinaryPath = ExampleMessages.findCLIBinary(from: testBundle)

		NSLog("[ExampleMessages] CLI binary: \(cliBinaryPath)")
		NSLog("[ExampleMessages] Broker file: \(brokerFilePath)")
	}

	private static func authTypeString(_ authType: AuthType?) -> String {
		switch authType {
		case .userPassword: return "usernamePassword"
		case .certificate: return "certificate"
		default: return "none"
		}
	}

	private static func findCLIBinary(from bundle: Bundle) -> String {
		var searchDir = bundle.bundleURL

		// Walk up from the test bundle looking for the mqtt-analyzer binary
		for _ in 0..<10 {
			searchDir = searchDir.deletingLastPathComponent()

			// Direct product: mqtt-analyzer in products dir
			let directPath = searchDir.appendingPathComponent("mqtt-analyzer").path
			if FileManager.default.fileExists(atPath: directPath) {
				return directPath
			}

			// Inside app bundle
			let appBundlePath = searchDir.appendingPathComponent("MQTTAnalyzer.app/Contents/MacOS/mqtt-analyzer").path
			if FileManager.default.fileExists(atPath: appBundlePath) {
				return appBundlePath
			}
		}

		// Last resort: return expected path for error messaging
		let productsGuess = bundle.bundleURL
			.deletingLastPathComponent()
			.deletingLastPathComponent()
			.deletingLastPathComponent()
			.deletingLastPathComponent()
		let expectedPath = productsGuess.appendingPathComponent("mqtt-analyzer").path
		NSLog("[ExampleMessages] WARNING: CLI binary not found, expected at \(expectedPath)")
		return expectedPath
	}

	func publish(_ topic: String, _ payload: String) {
		let cleanPayload = payload
			.replacingOccurrences(of: "\t", with: "")
			.replacingOccurrences(of: "\n", with: "")

		NSLog("[ExampleMessages] Publishing to \(topic) (\(cleanPayload.count) chars)")
		runCLI(args: ["publish", "-f", brokerFilePath, "--qos", "1", topic, cleanPayload])
	}

	func publish(_ topic: String, data: Data) {
		NSLog("[ExampleMessages] Publishing binary to \(topic) (\(data.count) bytes)")

		// Write binary data to a temp file and use --payload-file
		let tempFile = NSTemporaryDirectory() + "uitest-payload-\(UUID().uuidString).bin"
		FileManager.default.createFile(atPath: tempFile, contents: data)
		defer { try? FileManager.default.removeItem(atPath: tempFile) }

		runCLI(args: ["publish", "-f", brokerFilePath, "--qos", "1", "--payload-file", tempFile, topic])
	}

	/// Publishes vacuum bot map as PNG image
	func publishVacuumMap(prefix: String) {
		let testBundle = Bundle(for: type(of: self))
		if let logoData = LogoLoader.loadAppLogo(from: testBundle) {
			publish("\(prefix)vacuum/map", data: logoData)
		}
	}

	func publish(prefix: String) {
		// Dishwasher
		publish("\(prefix)dishwasher/000123456789",
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

		publish("\(prefix)dishwasher/000123456789/full",
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

		// Doorbell
		publish("\(prefix)doorbell/front",
"""
{
	"battery": 85,
	"status": "idle",
	"lastRing": "2026-03-21T09:15:00Z",
	"linkquality": 78
}
""")

		// Garage
		publish("\(prefix)garage/door",
"""
{
	"state": "closed",
	"lastChanged": "2026-03-21T08:30:00Z",
	"temperature": 12.4
}
""")

		// Light
		publish("\(prefix)light/kitchen/coffee-spot",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)light/kitchen/kitchen-1",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)light/kitchen/kitchen-2",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)light/kitchen/kitchen-3",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)light/kitchen/kitchen-4",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")
		publish("\(prefix)light/kitchen/kitchen-5",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":366}")

		publish("\(prefix)light/office/left",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")
		publish("\(prefix)light/office/center",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":233}")
		publish("\(prefix)light/office/right",
				"{\"state\":\"ON\",\"brightness\":100,\"color_temp\":230}")

		// Thermostat
		publish("\(prefix)thermostat/living-room",
"""
{
	"current_temperature": 21.5,
	"target_temperature": 22.0,
	"mode": "heat",
	"state": "heating",
	"battery": 72
}
""")

		// Vacuum (status - map is published separately as binary)
		publish("\(prefix)vacuum/status",
"""
{
	"state": "docked",
	"battery": 100,
	"cleanedArea": 42.5,
	"cleanTime": 35,
	"lastClean": "2026-03-21T07:00:00Z"
}
""")
	}

	func disconnect() {
		// Clean up the temporary broker file
		try? FileManager.default.removeItem(atPath: brokerFilePath)
	}

	// MARK: - CLI Process Runner

	private func runCLI(args: [String]) {
		let binary = cliBinaryPath
		guard FileManager.default.fileExists(atPath: binary) else {
			XCTFail("[ExampleMessages] CLI binary not found at \(binary)")
			return
		}

		let process = Process()
		process.executableURL = URL(fileURLWithPath: binary)
		process.arguments = args

		let stdoutPipe = Pipe()
		let stderrPipe = Pipe()
		process.standardOutput = stdoutPipe
		process.standardError = stderrPipe

		do {
			try process.run()
		} catch {
			XCTFail("[ExampleMessages] Failed to launch CLI: \(error)")
			return
		}

		// Timeout after 15 seconds
		DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
			if process.isRunning {
				NSLog("[ExampleMessages] CLI timed out, terminating")
				process.terminate()
			}
		}

		process.waitUntilExit()

		if process.terminationStatus != 0 {
			let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
			let stderrStr = String(data: stderrData, encoding: .utf8) ?? ""
			NSLog("[ExampleMessages] CLI exited with status \(process.terminationStatus): \(stderrStr)")
		}
	}
}
