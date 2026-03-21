//
//  TestServer.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 10.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class TestServer {
	static func getTestServer() -> String {
		return "test.mqtt.rnd7.de"
	}

	static func getTestPort() -> UInt16 {
		return 443
	}

	static func isTLS() -> Bool {
		return true
	}
}
