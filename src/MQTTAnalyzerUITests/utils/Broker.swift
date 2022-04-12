//
//  Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

enum ConnectionProtocol {
	case mqtt
	case websocket
}

enum AuthType {
	case none
	case userPassword
	case certificate
}

struct Broker {
	let alias: String?
	let hostname: String?
	var port: UInt16?
	var connectionProtocol: ConnectionProtocol?
	var authType: AuthType?
	var username: String?
	var password: String?
	var tls: Bool?
}
