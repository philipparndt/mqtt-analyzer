//
//  CertInfo.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-16.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Certificate information model containing parsed X.509 certificate data
struct CertInfo {
	var commonName: String?
	var issuer: String?
	var subjectAltNames: [String] = []
	var notBefore: Date?
	var notAfter: Date?
}
