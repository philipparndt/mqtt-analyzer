//
//  MQTTClientCocoaMQTT+OnMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

extension MQTTClientCocoaMQTT {
	func metadata(of message: CocoaMQTTMessage) -> MsgMetadata {
		return MsgMetadata(qos: Int32(message.qos.rawValue), retain: message.retained)
	}

	func payload(of message: CocoaMQTTMessage) -> MsgPayload {
		return MsgPayload(data: message.payload)
	}
	
	func topic(of message: CocoaMQTTMessage) -> String {
		return message.topic
	}
	
	func onMessageInMain(messages: [CocoaMQTTMessage]) {
		utils.onMessages(messages: messages,
						 metadata: self.metadata(of:),
						 payload: self.payload(of:),
						 topic: self.topic(of:))
	}
}
