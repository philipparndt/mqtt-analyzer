//
//  Handlers.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

protocol InitHost: AnyObject {
	func initHost(host: Host)
}

protocol ReconnectDelegate: AnyObject {
	func reconnect(host: Host)
}

protocol DisconnectDelegate: AnyObject {
	func disconnect(host: Host)
}
