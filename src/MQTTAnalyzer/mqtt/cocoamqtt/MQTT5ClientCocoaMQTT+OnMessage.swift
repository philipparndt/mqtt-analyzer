//
//  MQTT5ClientCocoaMQTT+OnMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

extension MQTT5ClientCocoaMQTT {
	func metadata(of message: CocoaMQTT5Message) -> MsgMetadata {
		return MsgMetadata(qos: Int32(message.qos.rawValue), retain: message.retained)
	}

	func payload(of message: CocoaMQTT5Message) -> MsgPayload {
		return MsgPayload(data: message.payload)
	}
	
	func topic(of message: CocoaMQTT5Message) -> String {
		return message.topic
	}
}
