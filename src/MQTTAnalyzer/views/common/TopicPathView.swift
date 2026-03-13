//
//  TopicPathView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicPathView: View {
	@Environment(\.colorScheme) var colorScheme
	@State private var showCopiedFeedback = false
	@State private var isMultiLine = false
	let topic: String

	var body: some View {
		HStack(spacing: 10) {
			Image(systemName: "arrow.triangle.branch")
				.font(.system(size: 14, weight: .medium))
				.foregroundColor(.secondary)

			Text(topic)
				.font(.system(.body, design: .monospaced))
				.textSelection(.enabled)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(
					GeometryReader { geometry in
						Color.clear.onAppear {
							isMultiLine = geometry.size.height > 24
						}
						.onChange(of: geometry.size.height) { _, newHeight in
							isMultiLine = newHeight > 24
						}
					}
				)

			#if os(macOS)
			Button(action: copyTopic) {
				Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
					.foregroundColor(showCopiedFeedback ? .green : .secondary)
					.frame(width: 16, height: 16)
			}
			.buttonStyle(.plain)
			.help("Copy topic")
			#endif
		}
		.padding(12)
		.background(Color.listItemBackground(colorScheme))
		.background(showCopiedFeedback ? Color.green.opacity(0.15) : Color.clear)
		.clipShape(isMultiLine ? AnyShape(RoundedRectangle(cornerRadius: 12)) : AnyShape(Capsule()))
		.animation(.easeInOut(duration: 0.2), value: showCopiedFeedback)
		.contextMenu {
			Button(action: copyTopic) {
				Label("Copy topic", systemImage: "doc.on.doc")
			}
		}
	}

	private func copyTopic() {
		Pasteboard.copy(topic)
		showCopiedFeedback = true
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			showCopiedFeedback = false
		}
	}
}
