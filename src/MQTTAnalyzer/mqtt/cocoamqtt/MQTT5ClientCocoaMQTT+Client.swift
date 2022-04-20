//
//  MQTT5ClientCocoaMQTT+OnMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

extension MQTT5ClientCocoaMQTT {
	func createClient(host: Host) -> CocoaMQTT5 {
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: utils.sanitizeBasePath(self.host.basePath))
			return CocoaMQTT5(clientID: host.computeClientID,
								  host: host.hostname,
								  port: host.port,
								  socket: websocket)

		}
		else {
			return CocoaMQTT5(clientID: host.computeClientID,
										  host: host.hostname,
										  port: host.port)
		}
	}
}
