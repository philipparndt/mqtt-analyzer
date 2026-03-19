//
//  MQTTProtocolCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-18.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Checks if the server speaks MQTT by sending a minimal CONNECT packet and validating the CONNACK response
final class MQTTProtocolCheck: BaseDiagnosticCheck, @unchecked Sendable {
	private var connection: NWConnection?

	final class CompletionState: @unchecked Sendable {
		private let lock = NSLock()
		private var _completed = false

		var completed: Bool {
			lock.lock()
			defer { lock.unlock() }
			return _completed
		}

		func markCompleted() -> Bool {
			lock.lock()
			defer { lock.unlock() }
			if _completed { return false }
			_completed = true
			return true
		}
	}

	init() {
		super.init(
			checkId: "mqtt_protocol",
			title: "MQTT Protocol",
			iconName: "message.and.waveform",
			dependencies: ["port"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let hostname = context.hostname
		let port = context.port
		let useTLS = context.tlsEnabled

		return await withCheckedContinuation { continuation in
			let host = NWEndpoint.Host(hostname)
			let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

			let parameters: NWParameters
			if context.tlsEnabled {
				let tlsOptions = DiagnosticTLSHelper.createTLSOptions(context: context)
				parameters = NWParameters(tls: tlsOptions)
			} else {
				parameters = NWParameters.tcp
			}

			let connection = NWConnection(host: host, port: nwPort, using: parameters)
			self.connection = connection

			let state = CompletionState()
			let startTime = start
			let checkSelf = self

			connection.stateUpdateHandler = { [weak self] connState in
				switch connState {
				case .ready:
					checkSelf.sendAndReceive(
						connection: connection, state: state, context: context,
						startTime: startTime, hostname: hostname, port: port
					) { result in
						self?.connection = nil
						continuation.resume(returning: result)
					}

				case .failed(let error):
					guard state.markCompleted() else { return }
					connection.cancel()
					self?.connection = nil
					let solutions = checkSelf.mTLSSolutions(context: context)
					continuation.resume(returning: .error(
						summary: "Connection failed",
						message: error.localizedDescription,
						duration: checkSelf.elapsed(since: startTime),
						solutions: solutions
					))

				case .cancelled:
					guard state.markCompleted() else { return }
					continuation.resume(returning: .warning(
						summary: "Check cancelled",
						message: "MQTT protocol check was cancelled",
						duration: checkSelf.elapsed(since: startTime)
					))

				case .setup, .preparing, .waiting:
					break

				@unknown default:
					break
				}
			}

			connection.start(queue: DispatchQueue(label: "mqtt-protocol-check"))

			// Timeout after 10 seconds
			DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
				guard state.markCompleted() else { return }
				connection.cancel()
				self?.connection = nil

				var solutions: [DiagnosticSolution] = [
					DiagnosticSolution("Verify that an MQTT broker is running on this port"),
					DiagnosticSolution("The port may be serving a different protocol (e.g. HTTPS)"),
					DiagnosticSolution(
						"If using a reverse proxy, check that it forwards MQTT traffic correctly"
					)
				]

				if port != 1883 {
					solutions.append(DiagnosticSolution(
						"Try MQTT default port 1883",
						quickFix: .changePort(1883)
					))
				}
				if port != 8883 {
					solutions.append(DiagnosticSolution(
						"Try MQTT TLS port 8883",
						quickFix: .changePort(8883)
					))
				}

				continuation.resume(returning: DiagnosticResult(
					status: .error("Server accepted connection but did not respond to MQTT"),
					summary: "No MQTT broker found",
					details: "The TCP connection was established but the server did not send "
						+ "an MQTT CONNACK response within 10 seconds.\n\n"
						+ "This typically means the service on this port is "
						+ "not an MQTT broker (e.g. a web server or reverse proxy).",
					duration: checkSelf.elapsed(since: startTime),
					solutions: solutions,
					commands: [
						DiagnosticCommand(label: "Test Port", command: "nc -zv \(hostname) \(port)"),
						DiagnosticCommand(
							label: "Check Service",
							command: "curl -v \(useTLS ? "https" : "http")://\(hostname):\(port)/ 2>&1 | head -20"
						)
					]
				))
			}
		}
	}

	override func cancel() {
		connection?.cancel()
		connection = nil
		super.cancel()
	}

}

// MARK: - Packet Building, Parsing & Protocol Detection

extension MQTTProtocolCheck {

	func sendAndReceive(
		connection: NWConnection, state: CompletionState,
		context: DiagnosticContext,
		startTime: CFAbsoluteTime, hostname: String, port: Int,
		onComplete: @escaping (DiagnosticResult) -> Void
	) {
		let connectPacket = buildMQTTConnectPacket()
		connection.send(content: connectPacket, completion: .contentProcessed { sendError in
			if let sendError = sendError {
				guard state.markCompleted() else { return }
				connection.cancel()
				onComplete(self.buildConnectionError(
					sendError, context: context, startTime: startTime
				))
				return
			}

			connection.receive(minimumIncompleteLength: 1, maximumLength: 256) { data, _, _, recvError in
				guard state.markCompleted() else { return }
				let duration = self.elapsed(since: startTime)
				connection.cancel()

				if let recvError = recvError {
					onComplete(self.buildReceiveError(
						recvError, context: context, duration: duration
					))
					return
				}

				guard let data = data, !data.isEmpty else {
					onComplete(self.buildEmptyResponseError(
						context: context, duration: duration
					))
					return
				}

				onComplete(self.parseCONNACK(
					data, duration: duration, hostname: hostname, port: port
				))
			}
		})
	}

	private func buildConnectionError(
		_ error: NWError, context: DiagnosticContext, startTime: CFAbsoluteTime
	) -> DiagnosticResult {
		.error(
			summary: "Failed to send MQTT CONNECT",
			message: error.localizedDescription,
			duration: elapsed(since: startTime),
			solutions: mTLSSolutions(context: context)
		)
	}

	private func buildReceiveError(
		_ error: NWError, context: DiagnosticContext, duration: TimeInterval
	) -> DiagnosticResult {
		let solutions = mTLSSolutions(context: context, fallback: [
			"The service on this port may not be an MQTT broker",
			"Check if the correct port is configured"
		])

		let isReset = isConnectionReset(error)
		let summary = isReset && context.tlsEnabled
			? "Connection rejected"
			: "No MQTT response"

		return .error(
			summary: summary,
			message: error.localizedDescription,
			duration: duration,
			solutions: solutions
		)
	}

	private func buildEmptyResponseError(
		context: DiagnosticContext, duration: TimeInterval
	) -> DiagnosticResult {
		let solutions = mTLSSolutions(context: context, fallback: [
			"The service on this port may not be an MQTT broker",
			"Check broker logs for connection rejection reasons"
		])

		return .error(
			summary: context.tlsEnabled ? "Connection rejected" : "No MQTT response",
			message: "Server closed connection without responding",
			duration: duration,
			solutions: solutions
		)
	}

	/// Build mTLS-aware solutions, falling back to generic ones
	private func mTLSSolutions(
		context: DiagnosticContext, fallback: [String] = []
	) -> [String] {
		let authType = context.host?.settings.authType ?? .none

		// Client cert is configured but failed to load
		if let identityError = context.clientIdentityError {
			return [
				"Client certificate error: \(identityError)",
				"Check the certificate file and password in broker settings"
			]
		}

		// TLS is enabled but no mTLS configured — server may require it
		if context.tlsEnabled && authType != .certificate && authType != .both {
			return [
				"The broker may require a client certificate (mTLS)",
				"Configure a client certificate in the broker's authentication settings"
			] + fallback
		}

		return fallback
	}

	private func isConnectionReset(_ error: NWError) -> Bool {
		if case .posix(let code) = error {
			return code == .ECONNRESET
		}
		return error.localizedDescription.contains("reset")
	}

	/// Build a minimal MQTT 3.1.1 CONNECT packet
	nonisolated func buildMQTTConnectPacket() -> Data {
		var packet = Data()
		packet.append(0x10) // CONNECT packet type
		packet.append(0x10) // Remaining length: 16 bytes
		packet.append(contentsOf: [0x00, 0x04])              // Length of "MQTT"
		packet.append(contentsOf: [0x4D, 0x51, 0x54, 0x54])  // "MQTT"
		packet.append(0x04)                                   // Protocol Level (3.1.1)
		packet.append(0x02)                                   // Connect Flags (clean session)
		packet.append(contentsOf: [0x00, 0x3C])               // Keep Alive: 60s
		packet.append(contentsOf: [0x00, 0x04])               // Client ID length
		packet.append(contentsOf: [0x64, 0x69, 0x61, 0x67])  // "diag"
		return packet
	}

	/// Parse a CONNACK response from the broker
	nonisolated func parseCONNACK(_ data: Data, duration: TimeInterval, hostname: String, port: Int) -> DiagnosticResult {
		let bytes = [UInt8](data)

		// CONNACK must be at least 4 bytes: fixed header (2) + variable header (2)
		guard bytes.count >= 4 else {
			return .error(
				summary: "Invalid MQTT response",
				message: "Response too short (\(bytes.count) bytes)",
				details: "Expected at least 4 bytes for CONNACK, got \(bytes.count).\nRaw: \(bytes.map { String(format: "0x%02X", $0) }.joined(separator: " "))",
				duration: duration,
				solutions: [
					"The service on this port may not be an MQTT broker",
					"The broker may use a different protocol version"
				]
			)
		}

		// Check packet type: CONNACK = 0x20
		let packetType = bytes[0] & 0xF0
		guard packetType == 0x20 else {
			let detected = detectProtocol(bytes)
			let summary = detected != nil ? "Not MQTT — \(detected!) detected" : "Not an MQTT broker"
			let message = detected != nil
				? "Server speaks \(detected!), not MQTT"
				: "Unexpected response (packet type: 0x\(String(format: "%02X", bytes[0])))"
			let rawHex = bytes.prefix(min(bytes.count, 32))
				.map { String(format: "0x%02X", $0) }.joined(separator: " ")

			return DiagnosticResult(
				status: .error(message),
				summary: summary,
				detailItems: [
					.text("Expected MQTT CONNACK, but received a \(detected ?? "unknown") response."),
					.code(rawHex)
				],
				duration: duration,
				solutions: protocolMismatchSolutions(detected: detected, port: port)
			)
		}

		// Parse return code (byte index 3)
		let returnCode = bytes[3]
		switch returnCode {
		case 0x00:
			return .success(
				summary: "MQTT broker confirmed",
				detailItems: [
					.field(label: "Response", value: "CONNACK (Connection Accepted)"),
					.field(label: "Broker", value: "\(hostname):\(port)")
				],
				duration: duration
			)
		case 0x01:
			return .warning(
				summary: "MQTT broker found (protocol version rejected)",
				message: "Unacceptable protocol version",
				details: "The broker rejected **MQTT 3.1.1**. It may require MQTT 5.0 or an older version.\n"
					+ "This confirms an MQTT broker is running at `\(hostname):\(port)`.",
				duration: duration,
				solutions: [
					"The broker may require MQTT 5.0",
					"Check broker configuration for supported protocol versions"
				]
			)
		case 0x02:
			return .success(
				summary: "MQTT broker confirmed",
				details: "Broker rejected the client identifier but confirmed it speaks MQTT.\nThe MQTT broker at `\(hostname):\(port)` is operational.",
				duration: duration
			)
		case 0x03:
			return .warning(
				summary: "MQTT broker unavailable",
				message: "Server unavailable",
				details: "The broker is running but reports itself as *unavailable*.\nCONNACK return code: `0x03` (Server Unavailable)",
				duration: duration,
				solutions: [
					"The broker may be starting up or shutting down",
					"Check broker health and logs",
					"Try again in a few moments"
				]
			)
		case 0x04:
			return .success(
				summary: "MQTT broker confirmed (auth required)",
				details: "Broker requires authentication (bad username or password).\nThis confirms an MQTT broker is running at `\(hostname):\(port)`.",
				duration: duration
			)
		case 0x05:
			return .success(
				summary: "MQTT broker confirmed (not authorized)",
				details: "Broker rejected authorization.\nThis confirms an MQTT broker is running at `\(hostname):\(port)`.",
				duration: duration
			)
		default:
			return .warning(
				summary: "MQTT broker found (unknown response)",
				message: "Unknown return code: 0x\(String(format: "%02X", returnCode))",
				details: "Received CONNACK with unknown return code "
					+ "0x\(String(format: "%02X", returnCode)).\n"
					+ "This indicates an MQTT broker is present but responded unexpectedly.",
				duration: duration,
				solutions: [
					"The broker may use a non-standard MQTT implementation",
					"Check broker logs for details"
				]
			)
		}
	}

	/// Detect the protocol from response bytes
	nonisolated func detectProtocol(_ bytes: [UInt8]) -> String? {
		let ascii = String(bytes: bytes.prefix(min(bytes.count, 64)), encoding: .ascii) ?? ""

		// HTTP responses
		if ascii.hasPrefix("HTTP/") { return "HTTP" }
		// HTTP request-like (some servers echo)
		if ascii.hasPrefix("GET ") || ascii.hasPrefix("POST ") { return "HTTP" }

		// SSH
		if ascii.hasPrefix("SSH-") { return "SSH" }

		// FTP
		if ascii.hasPrefix("220 ") || ascii.hasPrefix("220-") { return "FTP" }

		// SMTP
		if ascii.hasPrefix("250 ") || ascii.hasPrefix("250-") || ascii.hasPrefix("EHLO") { return "SMTP" }

		// POP3
		if ascii.hasPrefix("+OK") { return "POP3" }

		// IMAP
		if ascii.hasPrefix("* OK") { return "IMAP" }

		// Redis
		if ascii.hasPrefix("-ERR") || ascii.hasPrefix("+PONG") || ascii.hasPrefix("$") { return "Redis" }

		// MySQL
		if bytes.count > 4 && bytes[4] == 0x0A {
			// MySQL greeting: payload length (3 bytes) + seq (1 byte) + protocol version 0x0A
			let payloadLen = Int(bytes[0]) | (Int(bytes[1]) << 8) | (Int(bytes[2]) << 16)
			if payloadLen > 0 && payloadLen < 10000 && bytes[3] == 0x00 {
				return "MySQL"
			}
		}

		// PostgreSQL
		if ascii.contains("PostgreSQL") { return "PostgreSQL" }

		// TLS alert (connecting plaintext to a TLS port)
		if bytes.count >= 2 && bytes[0] == 0x15 && bytes[1] == 0x03 {
			return "TLS (try enabling TLS)"
		}

		// TLS ServerHello (unlikely but possible)
		if bytes.count >= 2 && bytes[0] == 0x16 && bytes[1] == 0x03 {
			return "TLS (try enabling TLS)"
		}

		// AMQP
		if ascii.hasPrefix("AMQP") { return "AMQP" }

		return nil
	}

	/// Build context-aware solutions for protocol mismatches
	nonisolated func protocolMismatchSolutions(
		detected: String?, port: Int
	) -> [DiagnosticSolution] {
		var solutions: [DiagnosticSolution] = []

		// TLS detected on a plaintext connection
		if let detected = detected, detected.contains("TLS") {
			solutions.append(DiagnosticSolution(
				"Enable TLS — the server requires an encrypted connection",
				quickFix: .enableTLS
			))
		} else {
			solutions.append(DiagnosticSolution(
				"The service on this port is not an MQTT broker"
			))
		}

		solutions.append(DiagnosticSolution(
			"Check if you're connecting to the correct port"
		))

		if port != 1883 {
			solutions.append(DiagnosticSolution(
				"Try MQTT default port 1883",
				quickFix: .changePort(1883)
			))
		}
		if port != 8883 {
			solutions.append(DiagnosticSolution(
				"Try MQTT TLS port 8883",
				quickFix: .changePort(8883)
			))
		}

		return solutions
	}
}
