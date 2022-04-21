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
		if host.protocolMethod == .websocket {
			let websocket = CocoaMQTTWebSocket(uri: utils.sanitizeBasePath(self.host.basePath))
			return CocoaMQTT(clientID: host.computeClientID,
								  host: host.hostname,
								  port: host.port,
								  socket: websocket)

		}
		else {
			return CocoaMQTT(clientID: host.computeClientID,
										  host: host.hostname,
										  port: host.port)
		}
	}
}
