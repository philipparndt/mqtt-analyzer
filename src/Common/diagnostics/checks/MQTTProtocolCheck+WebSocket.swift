//
//  MQTTProtocolCheck+WebSocket.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-05-26.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network
import Security

// MARK: - WebSocket Mode

extension MQTTProtocolCheck {

	func sendAndReceiveWebSocket(
		connection: NWConnection, state: CompletionState,
		context: DiagnosticContext,
		startTime: CFAbsoluteTime,
		onComplete: @escaping (DiagnosticResult) -> Void
	) {
		let path = normalizedWebSocketPath(context.host?.settings.basePath)
		let request = buildWebSocketUpgradeRequest(
			hostname: context.hostname, port: context.port, path: path
		)

		connection.send(content: request, completion: .contentProcessed { [weak self] sendError in
			guard let self = self else { return }
			if let sendError = sendError {
				guard state.markCompleted() else { return }
				connection.cancel()
				onComplete(self.buildConnectionError(
					sendError, context: context, startTime: startTime
				))
				return
			}

			self.receiveUntilHeadersComplete(
				connection: connection, accumulated: Data(), maxBytes: 16_384
			) { receiveResult in
				switch receiveResult {
				case .failure(let error):
					guard state.markCompleted() else { return }
					connection.cancel()
					onComplete(self.buildReceiveError(
						error, context: context, duration: self.elapsed(since: startTime)
					))
				case .empty:
					guard state.markCompleted() else { return }
					connection.cancel()
					onComplete(self.buildEmptyResponseError(
						context: context, duration: self.elapsed(since: startTime)
					))
				case .success(let data):
					guard let parsed = self.parseWebSocketUpgradeResponse(data) else {
						guard state.markCompleted() else { return }
						connection.cancel()
						onComplete(self.buildWebSocketUpgradeError(
							data: data, path: path,
							duration: self.elapsed(since: startTime)
						))
						return
					}

					if parsed.statusCode != 101 {
						guard state.markCompleted() else { return }
						connection.cancel()
						onComplete(self.buildWebSocketStatusError(
							response: parsed, path: path,
							duration: self.elapsed(since: startTime)
						))
						return
					}

					if let subprotocol = parsed.subprotocol,
					   !["mqtt", "mqttv3.1"].contains(subprotocol.lowercased()) {
						guard state.markCompleted() else { return }
						connection.cancel()
						onComplete(self.buildWebSocketSubprotocolError(
							subprotocol: subprotocol,
							duration: self.elapsed(since: startTime)
						))
						return
					}

					self.sendMQTTConnectOverWebSocket(
						connection: connection, state: state, context: context,
						startTime: startTime, leftover: parsed.leftover,
						onComplete: onComplete
					)
				}
			}
		})
	}

	private func sendMQTTConnectOverWebSocket(
		connection: NWConnection, state: CompletionState,
		context: DiagnosticContext,
		startTime: CFAbsoluteTime,
		leftover: Data,
		onComplete: @escaping (DiagnosticResult) -> Void
	) {
		let connectPacket = buildMQTTConnectPacket()
		let frame = encodeWebSocketBinaryFrame(payload: connectPacket)

		connection.send(content: frame, completion: .contentProcessed { [weak self] sendError in
			guard let self = self else { return }
			if let sendError = sendError {
				guard state.markCompleted() else { return }
				connection.cancel()
				onComplete(self.buildConnectionError(
					sendError, context: context, startTime: startTime
				))
				return
			}

			self.receiveCompleteWebSocketFrame(
				connection: connection, accumulated: leftover, maxBytes: 4096
			) { result in
				guard state.markCompleted() else { return }
				connection.cancel()
				let duration = self.elapsed(since: startTime)

				switch result {
				case .failure(let error):
					onComplete(self.buildReceiveError(
						error, context: context, duration: duration
					))
				case .empty:
					onComplete(self.buildEmptyResponseError(
						context: context, duration: duration
					))
				case .frame(let payload):
					onComplete(self.parseCONNACK(
						payload, context: context, duration: duration,
						hostname: context.hostname, port: context.port
					))
				}
			}
		})
	}
}

// MARK: - WebSocket Handshake

extension MQTTProtocolCheck {

	struct WebSocketUpgradeResponse {
		let statusCode: Int
		let statusReason: String
		let headers: [String: String]
		let subprotocol: String?
		let leftover: Data
	}

	nonisolated func normalizedWebSocketPath(_ basePath: String?) -> String {
		guard let raw = basePath?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
			return "/"
		}
		return raw.hasPrefix("/") ? raw : "/" + raw
	}

	nonisolated func buildWebSocketUpgradeRequest(
		hostname: String, port: Int, path: String
	) -> Data {
		let key = generateWebSocketKey()
		let lines = [
			"GET \(path) HTTP/1.1",
			"Host: \(hostname):\(port)",
			"Upgrade: websocket",
			"Connection: Upgrade",
			"Sec-WebSocket-Key: \(key)",
			"Sec-WebSocket-Version: 13",
			"Sec-WebSocket-Protocol: mqtt, mqttv3.1",
			"",
			""
		]
		return Data(lines.joined(separator: "\r\n").utf8)
	}

	nonisolated func generateWebSocketKey() -> String {
		var bytes = [UInt8](repeating: 0, count: 16)
		_ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		return Data(bytes).base64EncodedString()
	}

	nonisolated func parseWebSocketUpgradeResponse(_ data: Data) -> WebSocketUpgradeResponse? {
		let terminator: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A]
		let bytes = [UInt8](data)
		guard let endIndex = bytes.firstRange(of: terminator)?.lowerBound else { return nil }

		let headerData = bytes[..<endIndex]
		guard let headerString = String(bytes: headerData, encoding: .utf8) else { return nil }

		let lines = headerString.components(separatedBy: "\r\n")
		guard let statusLine = lines.first else { return nil }

		let statusParts = statusLine.split(separator: " ", maxSplits: 2,
		                                   omittingEmptySubsequences: false)
		guard statusParts.count >= 2,
		      statusParts[0].uppercased().hasPrefix("HTTP/"),
		      let code = Int(statusParts[1]) else {
			return nil
		}
		let reason = statusParts.count >= 3 ? String(statusParts[2]) : ""

		var headers: [String: String] = [:]
		for line in lines.dropFirst() {
			guard let colon = line.firstIndex(of: ":") else { continue }
			let name = line[..<colon].lowercased()
			let value = line[line.index(after: colon)...]
				.trimmingCharacters(in: .whitespaces)
			headers[name] = value
		}

		let leftoverStart = endIndex + terminator.count
		let leftover = leftoverStart < bytes.count
			? Data(bytes[leftoverStart...])
			: Data()

		return WebSocketUpgradeResponse(
			statusCode: code, statusReason: reason,
			headers: headers,
			subprotocol: headers["sec-websocket-protocol"],
			leftover: leftover
		)
	}

	func buildWebSocketUpgradeError(
		data: Data, path: String, duration: TimeInterval
	) -> DiagnosticResult {
		let bytes = [UInt8](data.prefix(64))
		let detected = detectProtocol(bytes)
		let rawHex = bytes.map { String(format: "0x%02X", $0) }.joined(separator: " ")

		var solutions: [DiagnosticSolution] = [
			DiagnosticSolution(
				"Switch to MQTT — the server may speak raw MQTT on this port",
				quickFix: .changeProtocolMethod(.mqtt)
			),
			DiagnosticSolution(
				"Verify the server supports MQTT over WebSocket"
			)
		]
		if detected == "TLS (try enabling TLS)" {
			solutions.insert(DiagnosticSolution(
				"Enable TLS — the server requires an encrypted connection",
				quickFix: .enableTLS
			), at: 0)
		}

		return DiagnosticResult(
			status: .error("Server did not return an HTTP upgrade response"),
			summary: "Invalid WebSocket response",
			detailItems: [
				.text("Expected an HTTP/1.1 response to the WebSocket upgrade on `\(path)`, "
					+ "but received \(detected ?? "non-HTTP") bytes."),
				.code(rawHex)
			],
			duration: duration,
			solutions: solutions
		)
	}

	func buildWebSocketStatusError(
		response: WebSocketUpgradeResponse, path: String, duration: TimeInterval
	) -> DiagnosticResult {
		var solutions: [DiagnosticSolution] = []
		let status = "\(response.statusCode) \(response.statusReason)".trimmingCharacters(in: .whitespaces)

		switch response.statusCode {
		case 400:
			solutions.append(DiagnosticSolution(
				"The broker rejected the WebSocket upgrade — check the path and headers"
			))
		case 401, 403:
			solutions.append(DiagnosticSolution(
				"The broker requires authentication for the WebSocket endpoint"
			))
		case 404:
			solutions.append(DiagnosticSolution(
				"The configured WebSocket path `\(path)` is not served by the broker"
			))
		case 426:
			solutions.append(DiagnosticSolution(
				"The broker requires a different WebSocket version"
			))
		case 500..<600:
			solutions.append(DiagnosticSolution(
				"The broker returned a server error — check broker logs"
			))
		default:
			solutions.append(DiagnosticSolution(
				"The broker returned HTTP \(response.statusCode) instead of 101 Switching Protocols"
			))
		}
		solutions.append(DiagnosticSolution(
			"Switch to MQTT — the server may speak raw MQTT on this port",
			quickFix: .changeProtocolMethod(.mqtt)
		))

		return DiagnosticResult(
			status: .error("WebSocket upgrade rejected (HTTP \(response.statusCode))"),
			summary: "WebSocket upgrade failed",
			detailItems: [
				.field(label: "Status", value: status),
				.field(label: "Path", value: path),
				.text("The server is reachable but did not switch to the WebSocket protocol.")
			],
			duration: duration,
			solutions: solutions
		)
	}

	func buildWebSocketSubprotocolError(
		subprotocol: String, duration: TimeInterval
	) -> DiagnosticResult {
		.error(
			summary: "WebSocket accepted but not MQTT",
			message: "Broker negotiated subprotocol `\(subprotocol)`",
			details: "The server upgraded to WebSocket but selected a non-MQTT subprotocol.\n"
				+ "Expected `mqtt` or `mqttv3.1`.",
			duration: duration,
			solutions: [
				"Verify the broker is configured to serve MQTT over WebSocket",
				"Some servers run a different WebSocket service on this endpoint"
			]
		)
	}
}

// MARK: - WebSocket Framing

extension MQTTProtocolCheck {

	enum WebSocketReceiveResult {
		case success(Data)
		case empty
		case failure(NWError)
	}

	enum WebSocketFrameResult {
		case frame(Data)
		case empty
		case failure(NWError)
	}

	/// Encode a single-frame binary WebSocket message with client-side masking (RFC 6455).
	nonisolated func encodeWebSocketBinaryFrame(payload: Data) -> Data {
		var frame = Data()
		frame.append(0x82) // FIN=1, opcode=0x2 (binary)

		var maskKey = [UInt8](repeating: 0, count: 4)
		_ = SecRandomCopyBytes(kSecRandomDefault, maskKey.count, &maskKey)

		let length = payload.count
		if length <= 125 {
			frame.append(0x80 | UInt8(length))
		} else if length < 65_536 {
			frame.append(0xFE) // 0x80 (mask) | 126
			frame.append(UInt8((length >> 8) & 0xFF))
			frame.append(UInt8(length & 0xFF))
		} else {
			frame.append(0xFF) // 0x80 (mask) | 127
			for shift in stride(from: 56, through: 0, by: -8) {
				frame.append(UInt8((length >> shift) & 0xFF))
			}
		}

		frame.append(contentsOf: maskKey)

		let payloadBytes = [UInt8](payload)
		var masked = [UInt8](repeating: 0, count: length)
		for index in 0..<length {
			masked[index] = payloadBytes[index] ^ maskKey[index % 4]
		}
		frame.append(contentsOf: masked)
		return frame
	}

	/// Try to decode the payload of a single WebSocket frame from `data`.
	/// Returns nil if the buffer is incomplete.
	nonisolated func decodeWebSocketFramePayload(_ data: Data) -> Data? {
		let bytes = [UInt8](data)
		guard bytes.count >= 2 else { return nil }

		let masked = (bytes[1] & 0x80) != 0
		var payloadLen = Int(bytes[1] & 0x7F)
		var offset = 2

		if payloadLen == 126 {
			guard bytes.count >= offset + 2 else { return nil }
			payloadLen = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
			offset += 2
		} else if payloadLen == 127 {
			guard bytes.count >= offset + 8 else { return nil }
			var len = 0
			for index in 0..<8 {
				len = (len << 8) | Int(bytes[offset + index])
			}
			payloadLen = len
			offset += 8
		}

		var maskKey: [UInt8] = []
		if masked {
			guard bytes.count >= offset + 4 else { return nil }
			maskKey = Array(bytes[offset..<offset + 4])
			offset += 4
		}

		guard bytes.count >= offset + payloadLen else { return nil }
		var payload = Array(bytes[offset..<offset + payloadLen])
		if masked {
			for index in 0..<payloadLen {
				payload[index] ^= maskKey[index % 4]
			}
		}
		return Data(payload)
	}

	func receiveUntilHeadersComplete(
		connection: NWConnection, accumulated: Data, maxBytes: Int,
		completion: @escaping (WebSocketReceiveResult) -> Void
	) {
		let terminator: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A]
		if [UInt8](accumulated).firstRange(of: terminator) != nil {
			completion(.success(accumulated))
			return
		}
		if accumulated.count >= maxBytes {
			completion(accumulated.isEmpty ? .empty : .success(accumulated))
			return
		}

		connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
			if let error = error {
				completion(.failure(error))
				return
			}

			var next = accumulated
			if let data = data { next.append(data) }

			if [UInt8](next).firstRange(of: terminator) != nil {
				completion(.success(next))
				return
			}

			if isComplete {
				completion(next.isEmpty ? .empty : .success(next))
				return
			}

			self.receiveUntilHeadersComplete(
				connection: connection, accumulated: next, maxBytes: maxBytes,
				completion: completion
			)
		}
	}

	func receiveCompleteWebSocketFrame(
		connection: NWConnection, accumulated: Data, maxBytes: Int,
		completion: @escaping (WebSocketFrameResult) -> Void
	) {
		if let payload = decodeWebSocketFramePayload(accumulated) {
			completion(.frame(payload))
			return
		}
		if accumulated.count >= maxBytes {
			completion(.empty)
			return
		}

		connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
			if let error = error {
				completion(.failure(error))
				return
			}

			var next = accumulated
			if let data = data { next.append(data) }

			if let payload = self.decodeWebSocketFramePayload(next) {
				completion(.frame(payload))
				return
			}

			if isComplete {
				completion(next.isEmpty ? .empty : .failure(.posix(.ENODATA)))
				return
			}

			self.receiveCompleteWebSocketFrame(
				connection: connection, accumulated: next, maxBytes: maxBytes,
				completion: completion
			)
		}
	}
}

// MARK: - Protocol Mismatch Probing

extension MQTTProtocolCheck {

	/// Run a short probe of the opposite transport. If the server responds correctly
	/// to that transport, return a definitive "wrong protocol selected" result.
	/// Otherwise, return the original primary result.
	func augmentWithProtocolMismatchProbe(
		primary: DiagnosticResult, context: DiagnosticContext
	) async -> DiagnosticResult {
		let hostname = context.hostname
		let port = context.port

		if context.useWebSocket {
			let speaksRawMQTT = await probeRawMQTT(context: context)
			guard speaksRawMQTT else { return primary }
			return DiagnosticResult(
				status: .error("WebSocket configured but server speaks raw MQTT"),
				summary: "Wrong protocol — server speaks raw MQTT",
				detailItems: [
					.field(label: "Broker", value: "\(hostname):\(port)"),
					.text("The server responded to a raw MQTT CONNECT but did not complete "
						+ "the WebSocket upgrade. The connection is configured to use WebSocket, "
						+ "which is likely the cause of connection failures.")
				],
				duration: primary.duration,
				solutions: [
					DiagnosticSolution(
						"Switch to MQTT",
						quickFix: .changeProtocolMethod(.mqtt)
					),
					DiagnosticSolution(
						"Or verify that the broker exposes MQTT over WebSocket on this port"
					)
				]
			)
		} else {
			let speaksWebSocket = await probeWebSocketUpgrade(context: context)
			guard speaksWebSocket else { return primary }
			return DiagnosticResult(
				status: .error("MQTT configured but server speaks WebSocket"),
				summary: "Wrong protocol — server speaks MQTT over WebSocket",
				detailItems: [
					.field(label: "Broker", value: "\(hostname):\(port)"),
					.text("The server completed a WebSocket upgrade handshake but did not respond "
						+ "to a raw MQTT CONNECT. The connection is configured to use raw MQTT, "
						+ "which is likely the cause of connection failures.")
				],
				duration: primary.duration,
				solutions: [
					DiagnosticSolution(
						"Switch to WebSocket",
						quickFix: .changeProtocolMethod(.websocket)
					),
					DiagnosticSolution(
						"Or verify that the broker exposes raw MQTT on this port"
					)
				]
			)
		}
	}

	/// Open a probe connection using the same TLS configuration as the primary check.
	private func makeProbeConnection(context: DiagnosticContext) -> NWConnection {
		let host = NWEndpoint.Host(context.hostname)
		let port = NWEndpoint.Port(integerLiteral: UInt16(context.port))
		let parameters: NWParameters
		if context.tlsEnabled {
			parameters = NWParameters(tls: DiagnosticTLSHelper.createTLSOptions(context: context))
		} else {
			parameters = .tcp
		}
		return NWConnection(host: host, port: port, using: parameters)
	}

	/// Lightweight probe: open a connection, send an MQTT CONNECT,
	/// and return true if the first response byte looks like a CONNACK (0x2X).
	private func probeRawMQTT(
		context: DiagnosticContext, timeout: TimeInterval = 3.0
	) async -> Bool {
		let connection = makeProbeConnection(context: context)
		let packet = buildMQTTConnectPacket()

		return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
			runProbe(
				connection: connection, queueLabel: "mqtt-protocol-probe-mqtt",
				timeout: timeout,
				onReady: { conn, finish in
					conn.send(content: packet, completion: .contentProcessed { error in
						if error != nil { finish(false); return }
						conn.receive(minimumIncompleteLength: 1, maximumLength: 64) { data, _, _, recvError in
							if recvError != nil { finish(false); return }
							guard let firstByte = data?.first else { finish(false); return }
							finish((firstByte & 0xF0) == 0x20)
						}
					})
				},
				onResult: { result in
					continuation.resume(returning: result)
				}
			)
		}
	}

	/// Lightweight probe: open a connection, send a WebSocket upgrade,
	/// and return true if the server responds with 101 Switching Protocols.
	private func probeWebSocketUpgrade(
		context: DiagnosticContext, timeout: TimeInterval = 3.0
	) async -> Bool {
		let connection = makeProbeConnection(context: context)
		let path = normalizedWebSocketPath(context.host?.settings.basePath)
		let request = buildWebSocketUpgradeRequest(
			hostname: context.hostname, port: context.port, path: path
		)

		return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
			runProbe(
				connection: connection, queueLabel: "mqtt-protocol-probe-ws",
				timeout: timeout,
				onReady: { [weak self] conn, finish in
					guard let self = self else { finish(false); return }
					conn.send(content: request, completion: .contentProcessed { error in
						if error != nil { finish(false); return }
						self.receiveUntilHeadersComplete(
							connection: conn, accumulated: Data(), maxBytes: 4096
						) { receiveResult in
							switch receiveResult {
							case .success(let data):
								finish(self.parseWebSocketUpgradeResponse(data)?.statusCode == 101)
							case .empty, .failure:
								finish(false)
							}
						}
					})
				},
				onResult: { result in
					continuation.resume(returning: result)
				}
			)
		}
	}

	/// Shared probe scaffolding: starts a pre-built connection, dispatches to `onReady`
	/// when it becomes ready, enforces a hard timeout, and delivers a single boolean
	/// result via `onResult`.
	private func runProbe(
		connection: NWConnection, queueLabel: String, timeout: TimeInterval,
		onReady: @escaping (NWConnection, @escaping (Bool) -> Void) -> Void,
		onResult: @escaping (Bool) -> Void
	) {
		let completion = CompletionState()

		let finish: (Bool) -> Void = { result in
			guard completion.markCompleted() else { return }
			connection.cancel()
			onResult(result)
		}

		connection.stateUpdateHandler = { state in
			switch state {
			case .ready:
				onReady(connection, finish)
			case .failed, .cancelled:
				finish(false)
			default:
				break
			}
		}

		connection.start(queue: DispatchQueue(label: queueLabel))

		DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
			finish(false)
		}
	}
}
