//
//  SyncMQTTDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 23.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import CocoaMQTT

class SyncMQTT5Delegate: CocoaMQTT5Delegate, SyncListener {
	private let semaphore = DispatchSemaphore(value: 1)
	
	private var pMessages = [MsgPayload]()
	
	private var pSents = [UInt16]()
	
	private var pConnected = false
	
	var connected: Bool {
		var result: Bool
		semaphore.wait()
		result = pConnected
		semaphore.signal()
		return result
	}
	
	var messages: [MsgPayload] {
		var result: [MsgPayload]
		semaphore.wait()
		result = pMessages
		semaphore.signal()
		return result
	}
	
	var sents: [UInt16] {
		var result: [UInt16]
		semaphore.wait()
		result = pSents
		semaphore.signal()
		return result
	}
	
	func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck) {
		semaphore.wait()
		pConnected = ack == .success
		semaphore.signal()
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
		semaphore.wait()
		pSents.append(id)
		semaphore.signal()
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish) {
		semaphore.wait()
		pMessages.append(MsgPayload(data: message.payload))
		semaphore.signal()
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], UnsubAckData: MqttDecodeUnsubAck) {
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
		semaphore.wait()
		pConnected = false
		semaphore.signal()
	}
	
	/// Manually validate SSL/TLS server certificate.
	///
	/// This method will be called if enable  `allowUntrustCACertificate`
	func mqtt5(_ mqtt5: CocoaMQTT5, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didPublishComplete id: UInt16, pubCompData: MqttDecodePubComp) {
		// currently not necessary, but required by protocol
	}

	func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
		// currently not necessary, but required by protocol
	}
}
