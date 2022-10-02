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
	
	func suggestAWSIOTChanges() -> Bool {
		if isAWS() {
			// mqtt not ws
			// cocoa not moscapsule
			// auth must be cert
			if port != "8883"
			|| !ssl
			|| untrustedSSL
			|| self.protocolMethod != .mqtt
			|| self.usernamePasswordAuth
			|| !self.certificateAuth
			|| self.protocolVersion != .mqtt3 {
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
		self.usernamePasswordAuth = false
		self.certificateAuth = true
		self.protocolVersion = .mqtt3
	}
}
