//
//  DiagnosticRunner.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

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

		// TLS layer checks (only when TLS enabled)
		if context.tlsEnabled {
			checks.append(TLSVersionCheck())
			checks.append(CertificateChainCheck())
			checks.append(CertificateExpiryCheck())
			checks.append(SANCheck())
			checks.append(EKUCheck())
		}
	}

	/// Run all diagnostic checks respecting dependencies
	func runAll() async {
		isRunning = true
		isCancelled = false

		// Reset all checks to pending
		for check in checks {
			check.status = .pending
			check.result = nil
		}

		// Build dependency graph and run checks
		var completed: Set<String> = []
		var remaining = checks

		while !remaining.isEmpty && !isCancelled {
			// Find checks whose dependencies are all satisfied
			let ready = remaining.filter { check in
				check.dependencies.allSatisfy { depId in
					// Dependency is satisfied if completed (regardless of success/failure)
					completed.contains(depId)
				}
			}

			if ready.isEmpty {
				// No checks ready - might have circular dependencies or all remaining have failed deps
				// Mark remaining as skipped
				for check in remaining {
					check.status = .warning("Skipped due to dependency failure")
					check.result = .skipped(reason: "A required check failed or was skipped")
				}
				break
			}

			// Run ready checks (can run in parallel if they don't share dependencies)
			await withTaskGroup(of: Void.self) { group in
				for check in ready {
					group.addTask {
						await self.runCheck(check)
					}
				}
			}

			// Move completed checks
			for check in ready {
				completed.insert(check.checkId)
				remaining.removeAll { $0.checkId == check.checkId }
			}

			// Check if any dependency failed - skip dependent checks
			for check in remaining {
				let failedDeps = check.dependencies.filter { depId in
					if let dep = checks.first(where: { $0.checkId == depId }) {
						return dep.status.isError
					}
					return false
				}

				if !failedDeps.isEmpty {
					check.status = .warning("Skipped")
					check.result = .skipped(reason: "Dependency check failed")
					completed.insert(check.checkId)
				}
			}

			remaining.removeAll { completed.contains($0.checkId) }
		}

		isRunning = false
	}

	/// Run a single check
	private func runCheck(_ check: any DiagnosticCheck) async {
		guard !isCancelled else { return }

		check.status = .running
		let result = await check.run(context: context)
		check.result = result
		check.status = result.status
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
