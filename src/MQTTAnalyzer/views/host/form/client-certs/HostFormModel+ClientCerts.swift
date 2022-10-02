//
//  HostFormModel+ClientCerts.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 16.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension HostFormModel {
	func isClientCerts() -> Bool {
		return certificateAuth
	}
	
	func suggestClientCertsTLSChanges() -> Bool {
		if isClientCerts() {
			if !ssl {
				return true
			}
		}
		return false
	}
	
	mutating func updateSettingsForClientCertsTLS() {
		self.ssl = true
		self.untrustedSSL = true
	}
}
