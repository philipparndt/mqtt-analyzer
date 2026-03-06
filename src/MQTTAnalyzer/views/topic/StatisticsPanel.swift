//
//  StatisticsPanel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-06.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: - Statistics Panel with Glass Effect
struct StatisticsPanel: View {
	@ObservedObject var model: TopicTree

	var body: some View {
		HStack(spacing: 14) {
			StatItem(icon: "number.square", label: "Topics", value: "\(model.topicCount)")
			StatItem(icon: "envelope", label: "Messages", value: "\(model.messageCount)")

			Divider()
				.frame(height: 24)

			ToolButton(icon: "circlebadge", help: "Mark all as read", action: model.markRead)
			ToolButton(icon: "trash", help: "Clear all", action: model.clear)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 6)
		.modifier(GlassPanelBackground())
	}
}

struct GlassPanelBackground: ViewModifier {
	func body(content: Content) -> some View {
		#if os(macOS)
		content
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
			.overlay(
				RoundedRectangle(cornerRadius: 10)
					.strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
			)
		#else
		if #available(iOS 26.0, *) {
			content
				.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 10))
		} else {
			content
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
				.overlay(
					RoundedRectangle(cornerRadius: 10)
						.strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
				)
		}
		#endif
	}
}

struct ToolButton: View {
	let icon: String
	let help: String
	let action: () -> Void

	@State private var isHovered = false

	var body: some View {
		Button(action: action) {
			Image(systemName: icon)
				.font(.callout)
				.foregroundStyle(isHovered ? .primary : .secondary)
				.frame(width: 24, height: 24)
				.contentShape(Rectangle())
				.background(
					RoundedRectangle(cornerRadius: 5)
						.fill(.primary.opacity(isHovered ? 0.1 : 0))
				)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			isHovered = hovering
		}
		.help(help)
	}
}

struct StatItem: View {
	let icon: String
	let label: String
	let value: String

	var body: some View {
		HStack(spacing: 6) {
			Image(systemName: icon)
				.font(.caption)
				.foregroundStyle(.secondary)

			VStack(alignment: .leading, spacing: 1) {
				Text(label)
					.font(.caption2)
					.foregroundStyle(.secondary)
				Text(value)
					.font(.callout)
					.fontWeight(.medium)
					.monospacedDigit()
			}
		}
	}
}
