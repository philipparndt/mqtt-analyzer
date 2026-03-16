//
//  ClientUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

class ClientUtils<T, M> {
	let connectionStateQueue = DispatchQueue(label: "connection.state.lock.queue")
	var connectionState = ConnectionState()
	let messageSubject = MsgSubject<ReceivedMessage<M>>()
	
	var host: Host
	let sessionNum: Int
	let model: TopicTree
	var mqtt: T?
	var connectionAlive: Bool {
		self.mqtt != nil && connectionState.state == .connected
	}
	
	init(host: Host, model: TopicTree) {
		ConnectionState.sessionNum += 1
		self.model = model
		self.sessionNum = ConnectionState.sessionNum
		self.host = host
	}
	
	func sanitizeBasePath(_ basePath: String) -> String {
		if basePath.starts(with: "/") {
			return basePath
		}
		else {
			return "/\(basePath)"
		}
	}
	
	func convertQOS(qos: Int32) -> CocoaMQTTQoS {
		switch qos {
		case 1:
			return CocoaMQTTQoS.qos1
		case 2:
			return CocoaMQTTQoS.qos2
		default:
			return CocoaMQTTQoS.qos0
		}
	}
	
	func connectedSuccess() {
		print("CONNECTION: onConnect \(sessionNum) \(host.settings.hostname)")
		self.connectionStateQueue.async {
			self.connectionState.state = .connected
		}

		NSLog("Connected.")
		DispatchQueue.main.async {
			self.host.state = .connected
		}
	}
	
	func clearAuth() {
		self.host.usernameNonpersistent = nil
		self.host.passwordNonpersistent = nil
	}
	
	func failConnection(reason: String) {
		NSLog("Connection failed: " + reason)
		self.connectionStateQueue.async {
			self.connectionState.message = reason
		}

		self.setDisconnected()

		DispatchQueue.main.async {
			self.host.connectionMessage = reason
			self.host.connectionErrorDetails = "Connection failed. Check your configuration and try again."
			self.host.pause = false
			self.host.state = .disconnected
		}

	}

	func buildErrorDetails(error: Error) -> String {
		NSLog("buildErrorDetails called with error: \(error)")
		let nsError = error as NSError
		let errorDesc = nsError.description.lowercased()

		NSLog("buildErrorDetails: domain=\(nsError.domain), description=\(nsError.description)")

		// For certificate errors: include in-app cert diagnostics
		if nsError.domain == "Network.NWError" &&
		   (nsError.description.starts(with: "-9808") || errorDesc.contains("certificate")) {
			NSLog("buildErrorDetails: Detected certificate error, calling CertificateDiagnostics.diagnose")
			return CertificateDiagnostics.diagnose(
				hostname: host.settings.hostname,
				host: host
			)
		}

		// For other errors: use existing static method
		NSLog("buildErrorDetails: Using extractErrorDetails for non-certificate error")
		return ClientUtils.extractErrorDetails(error: error)
	}
	
	func initConnect() {
		print("CONNECTION: connect \(sessionNum) \(host.settings.hostname)")
		host.connectionMessage = nil
		host.state = .connecting
		connectionState.state = .connecting
		connectionState.message = nil
		model.messageLimitExceeded = false
		model.topicLimitExceeded = false
	}
	
	func didDisconnect(_ client: T, withError err: Error?) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.settings.hostname)")

		if err != nil {
			let summary = ClientUtils.extractErrorSummary(error: err!)
			let details = buildErrorDetails(error: err!)

			self.connectionStateQueue.async {
				self.connectionState.message = summary
			}
			DispatchQueue.main.async {
				self.host.usernameNonpersistent = nil
				self.host.passwordNonpersistent = nil
				self.host.connectionMessage = summary
				self.host.connectionErrorDetails = details
				self.host.pause = false
				self.host.state = .disconnected
			}
		} else {
			DispatchQueue.main.async {
				self.host.pause = false
				self.host.state = .disconnected
			}
		}

		setDisconnected()
	}
	
	func setDisconnected() {
		print("CONNECTION: disconnected \(self.sessionNum) \(self.host.settings.hostname)")
		
		self.connectionStateQueue.async {
			self.connectionState.state = .disconnected
		}

		DispatchQueue.main.async {
			self.host.state = .disconnected
		}
		
		mqtt = nil
	}
	
	func installMessageDispatch(metadata: @escaping ((M) -> MsgMetadata), payload: @escaping ((M) -> MsgPayload), topic: @escaping ((M) -> String)) {
		let queue = DispatchQueue(label: "Message Dispatch queue")
		messageSubject.cancellable = messageSubject.subject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.1))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessages(messages: $0, metadata: metadata, payload: payload, topic: topic)
			})
	}
	
	func didReceiveMessage(message: ReceivedMessage<M>) {
		if !host.pause {
			messageSubject.send(message)
		}
	}
	
	func receiveMessagePreflight(amount: Int) -> Bool {
		if host.pause {
			return false
		}
		
		if amount > host.settings.limitMessagesBatch {
			// Limit exceeded
			self.model.messageLimitExceeded = true
			return false
		}
		
		return true
	}
	
	func onMessages<MT>(messages: [ReceivedMessage<MT>], metadata: ((MT) -> MsgMetadata), payload: ((MT) -> MsgPayload), topic: ((MT) -> String)) {
		if !receiveMessagePreflight(amount: messages.count) {
			return
		}
		
		for rmessage in messages {
			if host.settings.limitTopic > 0 && self.model.totalTopicCounter >= host.settings.limitTopic {
				// Limit exceeded
				self.model.topicLimitExceeded = true
			}
			
			let message = rmessage.message
			let messageMetadata = metadata(message)
			
			if let properties = rmessage.userProperty {
				for (key, value) in properties {
					messageMetadata.userProperty.append(Property(key: key, value: value))
				}
			}
			messageMetadata.responseTopic = rmessage.responseTopic
			
			let messagePayload = payload(message)
			messagePayload.contentType = rmessage.contentType
			
			_ = self.model.addMessage(
				metadata: messageMetadata,
				payload: messagePayload,
				to: topic(message)
			)
		}
	}
	
	func waitConnected() {
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			var i = 10
			
			var connecting = true
			
			while connecting && i > 0 {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.settings.hostname)")
				sleep(1)
				
				i-=1
				
				self.connectionStateQueue.sync {
					connecting = self.connectionState.state == .connecting
				}
			}
			group.leave()
		}

		group.notify(queue: .main) {
			if let errorMessage = self.connectionState.message {
				self.setDisconnected()
				self.host.connectionMessage = errorMessage
				return
			}

			if self.host.state != .connected {
				self.setDisconnected()

				self.setConnectionMessage(message: "Connection timeout")
			}
		}
	}
	
	func setConnectionMessage(message: String) {
		DispatchQueue.main.async {
			self.host.connectionMessage = message
		}
	}
	
	class func extractErrorSummary(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		let errorDesc = nsError.description.lowercased()

		if code == 8 {
			return "Invalid hostname"
		}
		else if nsError.domain == "Network.NWError" {
			if nsError.description.starts(with: "-9808") || errorDesc.contains("certificate") {
				if errorDesc.contains("not permitted for this usage") || errorDesc.contains("hostname") || errorDesc.contains("san") {
					return "Certificate validation failed - hostname mismatch"
				} else if errorDesc.contains("unknown") || errorDesc.contains("untrusted") {
					return "Certificate validation failed - untrusted CA"
				} else {
					return "Certificate validation failed"
				}
			}
			else {
				let groups = nsError.description.groups(for: ".*\\(rawValue:.(\\d+)\\):.(.*)")
				if groups.count == 1 && groups[0].count == 3 {
					return "\(groups[0][2])"
				}
				return "Network error"
			}
		}

		return "\(nsError.domain)"
	}

	class func extractErrorDetails(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		let errorDesc = nsError.description.lowercased()

		if code == 8 {
			return "The hostname appears to be invalid.\n\n\(error.localizedDescription)"
		}
		else if nsError.domain == "Network.NWError" {
			if nsError.description.starts(with: "-9808") || errorDesc.contains("certificate") {
				if errorDesc.contains("not permitted for this usage") || errorDesc.contains("hostname") || errorDesc.contains("san") {
					return "HOSTNAME MISMATCH\n\nThe certificate's CN or Subject Alternative Names (SAN) don't match your configured hostname.\n\nSOLUTION:\n" +
						"1. Verify your configured hostname matches the certificate's SAN/CN\n" +
						"2. Check the certificate details in the diagnostics above\n" +
						"3. If using a self-signed cert, ensure 'Allow Untrusted Certificates' is enabled in settings\n"
				} else if errorDesc.contains("unknown") || errorDesc.contains("untrusted") {
					return "UNTRUSTED CERTIFICATE\n\nThe Server CA certificate is missing, incorrect, or not trusted.\n\nSOLUTION:\n" +
						"1. Verify CA certificate file is correct and readable\n" +
						"2. Check certificate validity in the diagnostics above\n" +
						"3. Ensure the complete certificate chain is provided\n" +
						"4. If self-signed, enable 'Allow Untrusted Certificates' in settings\n"
				} else {
					return "CERTIFICATE VALIDATION ERROR\n\nCommon causes:\n" +
						"• Hostname in certificate doesn't match your configured hostname\n" +
						"• Missing or invalid CA certificate\n" +
						"• Certificate expired or not yet valid\n" +
						"• Certificate not in PEM format\n" +
						"• Self-signed certificate (enable 'Allow Untrusted Certificates')\n"
				}
			}
		}

		return "Error: \(nsError.domain) - \(nsError.description)"
	}
}
