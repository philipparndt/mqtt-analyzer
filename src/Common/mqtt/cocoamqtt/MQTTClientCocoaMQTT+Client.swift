//
//  MQTT5ClientCocoaMQTT+OnMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

extension MQTTClientCocoaMQTT {
	func createClient(host: Host) -> CocoaMQTT {
		if host.settings.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: utils.sanitizeBasePath(host.settings.basePath ?? ""))
			return CocoaMQTT(clientID: host.computeClientID,
							 host: host.settings.hostname,
							 port: UInt16(host.settings.port),
							 socket: websocket)

		}
		else {
			return CocoaMQTT(clientID: host.computeClientID,
							 host: host.settings.hostname,
							 port: UInt16(host.settings.port))
		}
	}
}
