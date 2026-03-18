//
//  PortCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Checks if the port is accessible via TCP connection
final class PortCheck: BaseDiagnosticCheck, @unchecked Sendable {
	private var connection: NWConnection?

	init() {
		super.init(
			checkId: "port",
			title: "Port Accessibility",
			iconName: "door.right.hand.open",
			dependencies: ["reachability"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()
		let port = context.port
		let hostname = context.hostname

		return await withCheckedContinuation { continuation in
			let host = NWEndpoint.Host(hostname)
			let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))

			let parameters = NWParameters.tcp
			parameters.allowLocalEndpointReuse = true

			let connection = NWConnection(host: host, port: nwPort, using: parameters)
			self.connection = connection

			// Use a class to safely manage completion state across callbacks
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

			let state = CompletionState()
			let startTime = start
			let checkSelf = self

			connection.stateUpdateHandler = { [weak self] connState in
				switch connState {
				case .ready:
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					continuation.resume(returning: .success(
						summary: "Port \(port) is open",
						details: "Successfully established TCP connection to **\(hostname):\(port)**",
						duration: duration
					))

				case .failed(let error):
					guard state.markCompleted() else { return }
					let duration = checkSelf.elapsed(since: startTime)
					connection.cancel()
					self?.connection = nil

					let errorMessage = checkSelf.describeError(error)
					continuation.resume(returning: .error(
						summary: "Port \(port) unreachable",
						message: errorMessage,
						details: "Failed to connect to **\(hostname):\(port)**\n\n**Error:** \(error.localizedDescription)",
						duration: duration,
						solutions: [
							"Verify the port number is correct (common MQTT ports: 1883, 8883 for TLS)",
							"Check if a firewall is blocking the connection",
							"Ensure the MQTT broker is running",
							"Verify the broker accepts connections on this port"
						],
						commands: [
							DiagnosticCommand(label: "Test Port", command: "nc -zv \(hostname) \(port)"),
							DiagnosticCommand(label: "Telnet Test", command: "telnet \(hostname) \(port)")
						]
					))

				case .waiting(let error):
					// Connection is waiting, might succeed later
					NSLog("PortCheck: Connection waiting - \(error.localizedDescription)")

				case .cancelled:
					guard state.markCompleted() else { return }
					continuation.resume(returning: .warning(
						summary: "Check cancelled",
						message: "Port check was cancelled",
						duration: checkSelf.elapsed(since: startTime)
					))

				case .setup, .preparing:
					break

				@unknown default:
					break
				}
			}

			connection.start(queue: DispatchQueue(label: "port-check"))

			// Timeout after 10 seconds
			DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
				guard state.markCompleted() else { return }
				connection.cancel()
				self?.connection = nil

				continuation.resume(returning: .error(
					summary: "Connection timed out",
					message: "TCP connection timed out after 10 seconds",
					details: "Could not establish TCP connection to **\(hostname):\(port)** within 10 seconds.",
					duration: checkSelf.elapsed(since: startTime),
					solutions: [
						"Check if the server is responding",
						"Verify firewall settings",
						"Try a different network connection",
						"Check if the broker is overloaded"
					],
					commands: [
						DiagnosticCommand(label: "Test Port", command: "nc -zv -w 5 \(hostname) \(port)")
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

	private nonisolated func describeError(_ error: NWError) -> String {
		if case .posix(let code) = error {
			switch code {
			case .ECONNREFUSED:
				return "Connection refused - port may be closed or service not running"
			case .ETIMEDOUT:
				return "Connection timed out"
			case .ENETUNREACH:
				return "Network unreachable"
			case .EHOSTUNREACH:
				return "Host unreachable"
			case .ECONNRESET:
				return "Connection reset by server"
			default:
				return "Connection error: \(code.rawValue)"
			}
		} else if case .dns(let dnsError) = error {
			return "DNS error: \(dnsError)"
		} else if case .tls(let tlsStatus) = error {
			return "TLS error: \(tlsStatus)"
		} else {
			return error.localizedDescription
		}
	}
}
