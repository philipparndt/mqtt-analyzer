//
//  SyncMQTTDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 23.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

class SyncMQTT5Delegate: CocoaMQTT5Delegate, SyncListener {
	let delegate = SyncDelegate()

	func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
		delegate.connect(connected: ack == .success)
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
		delegate.sent(id: id)
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
		delegate.received(payload: MsgPayload(data: message.payload))
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
		delegate.subscribed()
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], UnsubAckData: MqttDecodeUnsubAck?) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
		// currently not necessary, but required by protocol
	}
	
	func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
		// currently not necessary, but required by protocol
	}

	func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
		// currently not necessary, but required by protocol
	}

	func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
		// currently not necessary, but required by protocol
	}

	func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
		delegate.connect(connected: false)
	}
	
	/// Manually validate SSL/TLS server certificate.
	///
	/// This method will be called if enable  `allowUntrustCACertificate`
	func mqtt5(_ mqtt5: CocoaMQTT5, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishComplete id: UInt16, pubCompData: MqttDecodePubComp?) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
		// currently not necessary, but required by protocol
	}
}
