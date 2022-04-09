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

struct Broker {
	let alias: String?
	let hostname: String?
	var port: String?
	var connectionProtocol: ConnectionProtocol?
}
