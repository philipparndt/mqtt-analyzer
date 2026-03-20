//
//  DiagnosticRunner.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

/// Thread-safe tracker for check completion, enabling dependency-based parallel execution
private actor CompletionTracker {
	private var completed: Set<String> = []
	private var waiters: [String: [CheckedContinuation<Void, Never>]] = [:]

	func markCompleted(_ checkId: String) {
		completed.insert(checkId)
		if let continuations = waiters.removeValue(forKey: checkId) {
			for continuation in continuations {
				continuation.resume()
			}
		}
	}

	func waitForCompletion(of checkId: String) async {
		if completed.contains(checkId) { return }
		await withCheckedContinuation { continuation in
			waiters[checkId, default: []].append(continuation)
		}
	}
}

/// Orchestrates the execution of diagnostic checks with dependency resolution
@MainActor
class DiagnosticRunner: ObservableObject {
	/// All registered checks
	@Published private(set) var checks: [any DiagnosticCheck] = []

	/// Whether diagnostics are currently running
	@Published private(set) var isRunning = false

	/// The diagnostic context
	private(set) var context: DiagnosticContext

	/// Cancellation flag
	private var isCancelled = false

	init(context: DiagnosticContext) {
		self.context = context
		registerChecks()
	}

	/// Register all diagnostic checks
	private func registerChecks() {
		// Network layer checks (always run)
		checks.append(DNSResolutionCheck())
		checks.append(ReachabilityCheck())
		checks.append(PortCheck())
		checks.append(MQTTProtocolCheck())

		// TLS layer checks (only when TLS enabled)
		if context.tlsEnabled {
			checks.append(TLSVersionCheck())
			checks.append(CertificateChainCheck())
			checks.append(CertificateExpiryCheck())
			checks.append(SANCheck())
			checks.append(EKUCheck())
		}
	}

	/// Update context and re-register checks if needed (e.g. after quick fixes)
	func updateContext(hostname: String, port: Int,
	                   tlsEnabled: Bool, allowUntrusted: Bool,
	                   useWebSocket: Bool) {
		context.update(hostname: hostname, port: port, tlsEnabled: tlsEnabled,
					   allowUntrusted: allowUntrusted, useWebSocket: useWebSocket)
		// Re-register checks since TLS checks depend on tlsEnabled
		checks = []
		registerChecks()
	}

	/// Number of completed checks (for progress tracking)
	@Published private(set) var completedCount = 0

	/// Run all diagnostic checks, launching each as soon as its dependencies are met
	func runAll() async {
		isRunning = true
		isCancelled = false
		completedCount = 0

		// Reset all checks to pending
		for check in checks {
			check.status = .pending
			check.result = nil
		}

		// Track completed check IDs using an actor for thread-safe access
		let tracker = CompletionTracker()

		await withTaskGroup(of: Void.self) { group in
			for check in checks {
				group.addTask {
					await self.awaitDependenciesAndRun(check, tracker: tracker)
				}
			}
		}

		isRunning = false
	}

	/// Wait for a check's dependencies to complete, then run it
	private func awaitDependenciesAndRun(_ check: any DiagnosticCheck, tracker: CompletionTracker) async {
		// Wait for all dependencies to be completed
		for depId in check.dependencies {
			await tracker.waitForCompletion(of: depId)
		}

		guard !isCancelled else {
			await tracker.markCompleted(check.checkId)
			return
		}

		// Check if any dependency failed hard or was skipped — skip if so
		let shouldSkip = check.dependencies.contains { depId in
			if let dep = checks.first(where: { $0.checkId == depId }) {
				let wasSkipped = dep.result?.summary == "Skipped"
				let failedHard = dep.status.isError && !(dep.result?.continuable ?? false)
				return failedHard || wasSkipped
			}
			return false
		}

		if shouldSkip {
			check.status = .warning("Skipped")
			check.result = .skipped(reason: "Dependency check failed")
			completedCount += 1
			objectWillChange.send()
			await tracker.markCompleted(check.checkId)
			return
		}

		// Run the check
		check.status = .running
		objectWillChange.send()

		let result = await check.run(context: context)
		check.result = result
		check.status = result.status
		completedCount += 1
		objectWillChange.send()

		await tracker.markCompleted(check.checkId)
	}

	/// Cancel all running checks
	func cancel() {
		isCancelled = true
		for check in checks {
			check.cancel()
		}
		isRunning = false
	}

	/// Get a check by ID
	func check(withId id: String) -> (any DiagnosticCheck)? {
		checks.first { $0.checkId == id }
	}

	/// Overall status summary
	var overallStatus: DiagnosticStatus {
		if isRunning {
			return .running
		}

		let hasError = checks.contains { $0.status.isError }
		if hasError {
			return .error("One or more checks failed")
		}

		let hasWarning = checks.contains {
			if case .warning = $0.status { return true }
			return false
		}
		if hasWarning {
			return .warning("One or more checks have warnings")
		}

		let allSuccess = checks.allSatisfy {
			if case .success = $0.status { return true }
			return false
		}
		if allSuccess && !checks.isEmpty {
			return .success
		}

		return .pending
	}
}
