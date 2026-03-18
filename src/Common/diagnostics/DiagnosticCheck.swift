//
//  DiagnosticCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Status of a diagnostic check
enum DiagnosticStatus: Equatable, Sendable {
	case pending
	case running
	case success
	case warning(String)
	case error(String)

	var isTerminal: Bool {
		switch self {
		case .pending, .running:
			return false
		case .success, .warning, .error:
			return true
		}
	}

	var isError: Bool {
		if case .error = self {
			return true
		}
		return false
	}

	var message: String? {
		switch self {
		case .warning(let msg), .error(let msg):
			return msg
		default:
			return nil
		}
	}
}

/// A command that can help diagnose or fix an issue
struct DiagnosticCommand: Sendable {
	let label: String
	let command: String
}

/// Quick-fix action identifier for diagnostic solutions
enum DiagnosticQuickFix: Sendable {
	/// Enable "Allow Untrusted Certificates" on the broker
	case enableUntrusted
	/// Save the server's CA certificate chain to the broker settings
	case saveServerCA
}

/// A solution with an optional quick-fix action
struct DiagnosticSolution: Sendable {
	let text: String
	let quickFix: DiagnosticQuickFix?

	init(_ text: String, quickFix: DiagnosticQuickFix? = nil) {
		self.text = text
		self.quickFix = quickFix
	}
}

/// Structured content item for diagnostic detail display
enum DetailItem: Sendable {
	/// Plain text paragraph
	case text(String)
	/// Label-value pair (e.g. "Issuer" → "Let's Encrypt")
	case field(label: String, value: String)
	/// A value with a status indicator
	case fieldWithStatus(label: String, value: String, ok: Bool)
	/// Monospaced code/technical value
	case code(String)
	/// A titled section with nested items
	case section(title: String, items: [DetailItem])
	/// A list of values
	case list(items: [String])
}

/// Result of a diagnostic check
struct DiagnosticResult: Sendable {
	let status: DiagnosticStatus
	let summary: String
	let details: String?
	let detailItems: [DetailItem]
	let duration: TimeInterval
	let solutions: [DiagnosticSolution]
	let commands: [DiagnosticCommand]

	/// When true, dependent checks should still run even if this check failed.
	let continuable: Bool

	init(
		status: DiagnosticStatus,
		summary: String,
		details: String? = nil,
		detailItems: [DetailItem] = [],
		duration: TimeInterval = 0,
		solutions: [DiagnosticSolution] = [],
		commands: [DiagnosticCommand] = [],
		continuable: Bool = false
	) {
		self.status = status
		self.summary = summary
		self.details = details
		self.detailItems = detailItems
		self.duration = duration
		self.solutions = solutions
		self.commands = commands
		self.continuable = continuable
	}

	/// Convenience initializer accepting plain string solutions
	init(
		status: DiagnosticStatus,
		summary: String,
		details: String? = nil,
		detailItems: [DetailItem] = [],
		duration: TimeInterval = 0,
		solutions: [String],
		commands: [DiagnosticCommand] = [],
		continuable: Bool = false
	) {
		self.init(
			status: status, summary: summary,
			details: details, detailItems: detailItems,
			duration: duration,
			solutions: solutions.map { DiagnosticSolution($0) },
			commands: commands, continuable: continuable
		)
	}

	static func success(
		summary: String,
		details: String? = nil,
		detailItems: [DetailItem] = [],
		duration: TimeInterval = 0
	) -> DiagnosticResult {
		DiagnosticResult(
			status: .success, summary: summary,
			details: details, detailItems: detailItems, duration: duration
		)
	}

	static func warning(
		summary: String,
		message: String,
		details: String? = nil,
		detailItems: [DetailItem] = [],
		duration: TimeInterval = 0,
		solutions: [String] = [],
		commands: [DiagnosticCommand] = []
	) -> DiagnosticResult {
		DiagnosticResult(
			status: .warning(message),
			summary: summary,
			details: details,
			detailItems: detailItems,
			duration: duration,
			solutions: solutions,
			commands: commands
		)
	}

	static func error(
		summary: String,
		message: String,
		details: String? = nil,
		detailItems: [DetailItem] = [],
		duration: TimeInterval = 0,
		solutions: [String] = [],
		commands: [DiagnosticCommand] = []
	) -> DiagnosticResult {
		DiagnosticResult(
			status: .error(message),
			summary: summary,
			details: details,
			detailItems: detailItems,
			duration: duration,
			solutions: solutions,
			commands: commands
		)
	}

	static func skipped(reason: String) -> DiagnosticResult {
		DiagnosticResult(status: .warning(reason), summary: "Skipped", details: reason)
	}
}

/// Protocol for diagnostic checks
protocol DiagnosticCheck: AnyObject {
	/// Unique identifier for this check
	var checkId: String { get }

	/// Human-readable title
	var title: String { get }

	/// SF Symbol icon name
	var iconName: String { get }

	/// Current status of the check
	var status: DiagnosticStatus { get set }

	/// Latest result (nil if not yet run)
	var result: DiagnosticResult? { get set }

	/// IDs of checks that must complete successfully before this one runs
	var dependencies: [String] { get }

	/// Run the diagnostic check
	func run(context: DiagnosticContext) async -> DiagnosticResult

	/// Cancel the check if running
	func cancel()
}

/// Base class for diagnostic checks providing common functionality
class BaseDiagnosticCheck: DiagnosticCheck, ObservableObject {
	let checkId: String
	let title: String
	let iconName: String
	let dependencies: [String]

	@Published var status: DiagnosticStatus = .pending
	@Published var result: DiagnosticResult?

	private var task: Task<Void, Never>?

	init(checkId: String, title: String, iconName: String, dependencies: [String] = []) {
		self.checkId = checkId
		self.title = title
		self.iconName = iconName
		self.dependencies = dependencies
	}

	func run(context: DiagnosticContext) async -> DiagnosticResult {
		fatalError("Subclasses must override run(context:)")
	}

	func cancel() {
		task?.cancel()
		task = nil
		if !status.isTerminal {
			status = .warning("Cancelled")
		}
	}

	func startTiming() -> CFAbsoluteTime {
		CFAbsoluteTimeGetCurrent()
	}

	func elapsed(since start: CFAbsoluteTime) -> TimeInterval {
		CFAbsoluteTimeGetCurrent() - start
	}
}
