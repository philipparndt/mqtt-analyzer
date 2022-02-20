//
//  AWSIOTPreset.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-09.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

extension HostFormModel {
	func isAWS() -> Bool {
		return hostname.lowercased().hasSuffix("amazonaws.com")
		&& hostname.lowercased().contains(".iot.")
	}
	
	func suggestAWSIOTCHanges() -> Bool {
		if isAWS() {
			// mqtt not ws
			// cocoa not moscapsule
			// auth must be cert
			if port != "8883"
			|| !ssl
			|| untrustedSSL
			|| self.protocolMethod != .mqtt
			|| self.authType != .certificate
			|| self.clientImpl != .cocoamqtt {
				return true
			}
		}
		return false
	}
	
	mutating func updateSettingsForAWSIOT() {
		self.port = "8883"
		self.ssl = true
		self.untrustedSSL = false
		self.protocolMethod = .mqtt
		self.authType = .certificate
		self.clientImpl = .cocoamqtt
	}
}
