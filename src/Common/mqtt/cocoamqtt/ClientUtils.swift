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
}

// MARK: - Connection Lifecycle
extension ClientUtils {
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
			let nsErr = err! as NSError
			NSLog("CONNECTION ERROR: domain=\(nsErr.domain) code=\(nsErr.code) desc=\(nsErr.description)")
			let summary = self.extractErrorSummary(error: err!)
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
}

// MARK: - Message Handling
extension ClientUtils {
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
}

// MARK: - Error Handling
extension ClientUtils {
	func buildErrorDetails(error: Error) -> String {
		let nsError = error as NSError
		let errorDesc = nsError.description.lowercased()

		if nsError.domain == "Network.NWError" {
			// Check mTLS first — before generic certificate error handling
			if isMTLSFailureLikely(errorDesc) {
				return Self.extractErrorDetails(error: error)
			}

			// For certificate errors: include in-app cert diagnostics
			if nsError.description.starts(with: "-9808") || errorDesc.contains("certificate") {
				return CertificateDiagnostics.diagnose(
					hostname: host.settings.hostname,
					host: host
				)
			}
		} else if nsError.domain == NSURLErrorDomain {
			return Self.buildURLErrorDetails(nsError)
		}

		return Self.extractErrorDetails(error: error)
	}

	/// Instance method with host context for better mTLS detection
	func extractErrorSummary(error: Error) -> String {
		let nsError = error as NSError
		let errorDesc = nsError.description.lowercased()

		// Check mTLS with host context first
		if nsError.domain == "Network.NWError" && isMTLSFailureLikely(errorDesc) {
			return "TLS handshake rejected — server may require client certificate (mTLS)"
		}

		return Self.extractErrorSummary(error: error)
	}

	/// Detect if a TLS error is likely caused by missing client certificate (mTLS).
	/// Uses host context: if TLS is enabled but no client cert is configured,
	/// many TLS errors are likely mTLS rejections.
	private func isMTLSFailureLikely(_ errorDesc: String) -> Bool {
		// Explicit handshake failure indicators (always mTLS)
		if errorDesc.contains("handshake") || errorDesc.contains("-9824") {
			return true
		}

		// For other TLS errors: check if mTLS is expected but not configured
		guard host.settings.ssl else { return false }
		let authType = host.settings.authType
		let hasMTLS = authType == .certificate || authType == .both
		if hasMTLS { return false } // mTLS is configured, so the error is something else

		// TLS enabled, no client cert configured — these errors suggest mTLS is required:
		// -9829: "unknown certificate" — server rejected client (no cert presented)
		// "certificate required" — explicit TLS alert 116
		// Do NOT match -9808 here — that's a server cert validation error
		if errorDesc.contains("-9829") || errorDesc.contains("certificate required") {
			return true
		}

		return false
	}
}

// MARK: - Static Error Classification
extension ClientUtils {
	class func extractErrorSummary(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		let errorDesc = nsError.description.lowercased()

		if code == 8 {
			return "Invalid hostname"
		} else if nsError.domain == "Network.NWError" {
			if isMTLSFailureLikely(errorDesc) {
				return "TLS handshake rejected — server may require client certificate (mTLS)"
			} else if nsError.description.starts(with: "-9808") || errorDesc.contains("certificate") {
				return classifyCertError(errorDesc)
			} else {
				let groups = nsError.description.groups(for: ".*\\(rawValue:.(\\d+)\\):.(.*)")
				if groups.count == 1 && groups[0].count == 3 {
					return "\(groups[0][2])"
				}
				return "Network error"
			}
		} else if nsError.domain == NSURLErrorDomain {
			return classifyURLError(nsError)
		}

		return "\(nsError.domain) (\(code))"
	}

	private class func classifyCertError(_ errorDesc: String) -> String {
		let code = extractErrorCode(errorDesc)
		let suffix = code != nil ? " (\(code!))" : ""

		if errorDesc.contains("not permitted for this usage") || errorDesc.contains("hostname")
			|| errorDesc.contains("san") {
			return "Certificate hostname mismatch" + suffix
		} else if errorDesc.contains("not standards compliant") {
			return "Certificate does not meet Apple's requirements" + suffix
		} else if errorDesc.contains("unknown") || errorDesc.contains("untrusted") {
			return "Certificate not trusted — add Server CA or enable 'Allow Untrusted'" + suffix
		} else if errorDesc.contains("expired") {
			return "Certificate has expired" + suffix
		} else {
			return "Certificate validation failed" + suffix
		}
	}

	private class func extractErrorCode(_ errorDesc: String) -> String? {
		// NWError descriptions start with the code, e.g. "-9808: bad certificate format"
		if let match = errorDesc.range(of: #"^-?\d+"#, options: .regularExpression) {
			return String(errorDesc[match])
		}
		return nil
	}

	class func extractErrorDetails(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		let errorDesc = nsError.description.lowercased()

		if code == 8 {
			return "The hostname appears to be invalid."
		} else if nsError.domain == "Network.NWError" {
			if isMTLSFailureLikely(errorDesc) {
				return "The server rejected the TLS handshake.\n\n"
					+ "This usually means the server requires a client certificate (mTLS).\n\n"
					+ "Configure a client certificate in the authentication settings, "
					+ "or run diagnostics for more details."
			} else if nsError.description.starts(with: "-9808") || errorDesc.contains("certificate") {
				return buildCertErrorDetails(errorDesc)
			}
		} else if nsError.domain == NSURLErrorDomain {
			return buildURLErrorDetails(nsError)
		}

		return "Error: \(nsError.domain) - \(nsError.description)"
	}

	/// Static variant for class methods that don't have host context.
	/// Only matches explicit handshake/mTLS indicators.
	private class func isMTLSFailureLikely(_ errorDesc: String) -> Bool {
		errorDesc.contains("handshake") || errorDesc.contains("-9824")
			|| errorDesc.contains("certificate required")
	}

	private class func classifyURLError(_ nsError: NSError) -> String {
		switch nsError.code {
		case -1200: // NSURLErrorSecureConnectionFailed
			return "TLS connection failed"
		case -1201: // NSURLErrorServerCertificateHasBadDate
			return "Certificate has expired or is not yet valid"
		case -1202: // NSURLErrorServerCertificateUntrusted
			return "Certificate not trusted — add Server CA or enable 'Allow Untrusted'"
		case -1203: // NSURLErrorServerCertificateHasUnknownRoot
			return "Certificate has unknown root CA"
		case -1204: // NSURLErrorServerCertificateNotYetValid
			return "Certificate is not yet valid"
		case -1205: // NSURLErrorClientCertificateRejected
			return "Client certificate was rejected by the server"
		case -1206: // NSURLErrorClientCertificateRequired
			return "Server requires a client certificate (mTLS)"
		case -1001: // NSURLErrorTimedOut
			return "Connection timed out"
		case -1003: // NSURLErrorCannotFindHost
			return "Cannot find host"
		case -1004: // NSURLErrorCannotConnectToHost
			return "Cannot connect to host"
		case -1005: // NSURLErrorNetworkConnectionLost
			return "Connection lost"
		default:
			return "Connection failed (\(nsError.code))"
		}
	}

	private class func buildURLErrorDetails(_ nsError: NSError) -> String {
		switch nsError.code {
		case -1200: // NSURLErrorSecureConnectionFailed
			return "The TLS connection failed.\n\n"
				+ "This often happens when WebSocket is selected but the server "
				+ "expects raw MQTT, or vice versa.\n\n"
				+ "Run diagnostics to check the protocol configuration, "
				+ "or try switching between MQTT and WebSocket."
		case -1201, -1204:
			return "The server certificate date is invalid.\n\n"
				+ "Contact the broker administrator to renew the certificate."
		case -1202, -1203:
			return "The server certificate is not trusted.\n\n"
				+ "Add the broker's CA certificate as 'Server CA' in the TLS settings, "
				+ "or enable 'Allow Untrusted Certificates'.\n\n"
				+ "Run diagnostics to inspect the certificate and apply a quick fix."
		case -1205:
			return "The server rejected the client certificate.\n\n"
				+ "Check that the correct client certificate is configured "
				+ "and that the password is correct."
		case -1206:
			return "The server requires a client certificate (mTLS).\n\n"
				+ "Configure a client certificate in the authentication settings."
		default:
			return "Connection failed: \(nsError.localizedDescription)\n\n"
				+ "Run diagnostics for more details."
		}
	}

	private class func buildCertErrorDetails(_ errorDesc: String) -> String {
		if errorDesc.contains("not permitted for this usage") || errorDesc.contains("hostname")
			|| errorDesc.contains("san") {
			return "The certificate's Subject Alternative Names (SAN) "
				+ "don't match the configured hostname.\n\n"
				+ "Run diagnostics to see the certificate details and matching hostnames."
		} else if errorDesc.contains("not standards compliant") {
			return "The server certificate does not meet Apple's requirements "
				+ "(e.g. validity > 825 days or missing SAN extension).\n\n"
				+ "Enable 'Allow Untrusted Certificates' to connect."
		} else if errorDesc.contains("unknown") || errorDesc.contains("untrusted") {
			return "The server certificate is not trusted.\n\n"
				+ "Add the broker's CA certificate as 'Server CA' in the TLS settings, "
				+ "or enable 'Allow Untrusted Certificates'.\n\n"
				+ "Run diagnostics to inspect the certificate and apply a quick fix."
		} else if errorDesc.contains("expired") {
			return "The server certificate has expired.\n\n"
				+ "Contact the broker administrator to renew the certificate."
		} else {
			return "Certificate validation failed.\n\n"
				+ "Run diagnostics for detailed certificate analysis and quick fixes."
		}
	}
}
