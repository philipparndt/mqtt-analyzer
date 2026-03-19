//
//  ReachabilityCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Checks if the network path to the host exists
final class ReachabilityCheck: BaseDiagnosticCheck, @unchecked Sendable {

	init() {
		super.init(
			checkId: "reachability",
			title: "Network Reachability",
			iconName: "wifi",
			dependencies: ["dns"]
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()

		return await withCheckedContinuation { continuation in
			let monitor = NWPathMonitor()
			let queue = DispatchQueue(label: "reachability-check")

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

			monitor.pathUpdateHandler = { path in
				guard state.markCompleted() else { return }
				monitor.cancel()

				context.networkPath = path
				let duration = checkSelf.elapsed(since: startTime)

				switch path.status {
				case .satisfied:
					var details = "Network path is available"
					if path.isExpensive {
						details += " (cellular/expensive)"
					}
					if path.isConstrained {
						details += " (low data mode)"
					}

					let interfaces = path.availableInterfaces.map { $0.name }.joined(separator: ", ")
					if !interfaces.isEmpty {
						details += "\nInterfaces: \(interfaces)"
					}

					continuation.resume(returning: .success(
						summary: "Network available",
						details: details,
						duration: duration
					))

				case .unsatisfied:
					continuation.resume(returning: .error(
						summary: "No network",
						message: "No network path available",
						details: "Your device does not have network connectivity.",
						duration: duration,
						solutions: [
							"Check WiFi or cellular connection",
							"Disable airplane mode if enabled",
							"Check if VPN is required for this network"
						],
						commands: [
							DiagnosticCommand(label: "Network Status", command: "networksetup -getairportnetwork en0")
						]
					))

				case .requiresConnection:
					continuation.resume(returning: .warning(
						summary: "Connection required",
						message: "Network requires activation",
						details: "The network path requires connection activation (e.g., VPN or on-demand connection).",
						duration: duration,
						solutions: [
							"Connect to VPN if required",
							"Check network settings"
						]
					))

				@unknown default:
					continuation.resume(returning: .warning(
						summary: "Unknown status",
						message: "Network status unknown",
						duration: duration
					))
				}
			}

			monitor.start(queue: queue)

			// Timeout after 5 seconds
			queue.asyncAfter(deadline: .now() + 5) {
				guard state.markCompleted() else { return }
				monitor.cancel()

				continuation.resume(returning: .warning(
					summary: "Check timed out",
					message: "Reachability check timed out",
					duration: checkSelf.elapsed(since: startTime)
				))
			}
		}
	}
}
