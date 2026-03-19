//
//  DiagnosticPanelView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DiagnosticPanelView: View {
	@ObservedObject var check: BaseDiagnosticCheck
	let context: DiagnosticContext
	var formModel: Binding<HostFormModel>?
	@State private var isExpanded = false

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			// Header
			Button {
				if check.result != nil {
					withAnimation(.easeInOut(duration: 0.2)) {
						isExpanded.toggle()
					}
				}
			} label: {
				HStack(spacing: 12) {
					DiagnosticStatusIcon(status: check.status)

					Image(systemName: check.iconName)
						.font(.system(size: 14))
						.foregroundColor(.secondary)
						.frame(width: 20)

					VStack(alignment: .leading, spacing: 2) {
						Text(check.title)
							.font(.subheadline)
							.fontWeight(.medium)
							.foregroundColor(.primary)

						if let result = check.result {
							Text(result.summary)
								.font(.caption)
								.foregroundColor(.secondary)
								.lineLimit(1)
						} else if case .running = check.status {
							Text("Checking...")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}

					Spacer()

					if check.result != nil {
						Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 10)
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)

			// Expanded content
			if isExpanded, let result = check.result {
				Divider()
					.padding(.leading, 48)

				DiagnosticResultView(result: result, context: context, formModel: formModel)
					.padding(.horizontal, 12)
					.padding(.vertical, 10)
					.padding(.leading, 36)
			}
		}
		.background(Color.primary.opacity(0.03))
		.cornerRadius(8)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.strokeBorder(borderColor, lineWidth: 1)
		)
		.onChange(of: check.status) { _, newStatus in
			// Auto-expand on error
			if case .error = newStatus {
				withAnimation {
					isExpanded = true
				}
			}
		}
	}

	private var borderColor: Color {
		switch check.status {
		case .error:
			return .red.opacity(0.3)
		case .warning:
			return .orange.opacity(0.3)
		case .success:
			return .green.opacity(0.2)
		default:
			return .primary.opacity(0.1)
		}
	}
}
