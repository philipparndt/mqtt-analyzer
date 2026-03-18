//
//  DiagnosticResultView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DiagnosticResultView: View {
	let result: DiagnosticResult
	@State private var copiedCommand: String?

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Details section
			if let details = result.details {
				VStack(alignment: .leading, spacing: 4) {
					Text("Details")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					Text(details)
						.font(.callout)
						.textSelection(.enabled)
						.fixedSize(horizontal: false, vertical: true)
				}
			}

			// Duration
			if result.duration > 0 {
				HStack {
					Image(systemName: "clock")
						.font(.caption)
						.foregroundColor(.secondary)
					Text(formatDuration(result.duration))
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}

			// Solutions section
			if !result.solutions.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					Text("Solutions")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					VStack(alignment: .leading, spacing: 6) {
						ForEach(Array(result.solutions.enumerated()), id: \.offset) { index, solution in
							HStack(alignment: .top, spacing: 8) {
								Text("\(index + 1).")
									.font(.callout)
									.fontWeight(.medium)
									.foregroundColor(.secondary)
									.frame(width: 20, alignment: .leading)

								Text(solution)
									.font(.callout)
									.fixedSize(horizontal: false, vertical: true)
							}
						}
					}
				}
				.padding(.top, 4)
			}

			// Commands section
			if !result.commands.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					Text("Useful Commands")
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(.secondary)

					ForEach(result.commands, id: \.command) { cmd in
						CommandView(command: cmd, copiedCommand: $copiedCommand)
					}
				}
				.padding(.top, 4)
			}
		}
	}

	private func formatDuration(_ duration: TimeInterval) -> String {
		if duration < 1 {
			return String(format: "%.0f ms", duration * 1000)
		} else {
			return String(format: "%.2f s", duration)
		}
	}
}

struct CommandView: View {
	let command: DiagnosticCommand
	@Binding var copiedCommand: String?

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(command.label)
				.font(.caption)
				.foregroundColor(.secondary)

			HStack {
				Text(command.command)
					.font(.system(.caption, design: .monospaced))
					.textSelection(.enabled)
					.padding(8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color.primary.opacity(0.05))
					.cornerRadius(6)

				Button {
					Pasteboard.copy(command.command)
					copiedCommand = command.command
					DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
						if copiedCommand == command.command {
							copiedCommand = nil
						}
					}
				} label: {
					Image(systemName: copiedCommand == command.command ? "checkmark" : "doc.on.doc")
						.font(.caption)
						.foregroundColor(copiedCommand == command.command ? .green : .secondary)
				}
				.buttonStyle(.plain)
				.help("Copy to clipboard")
			}
		}
	}
}
