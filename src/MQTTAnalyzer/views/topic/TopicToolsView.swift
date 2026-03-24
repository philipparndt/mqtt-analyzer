//
//  TopicToolsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsToolsView: View {
	@ObservedObject var model: TopicTree

	var body: some View {
		Group {
			HStack {
				Text("Topics/Messages")
				Spacer()
				Text("\(model.topicCount)/\(model.messageCount)")
					.font(.system(.subheadline, design: .monospaced))
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(Color.accentColor.opacity(0.15))
					.cornerRadius(8)

				#if !targetEnvironment(macCatalyst)
				Button(action: model.markRead) {
					Button(action: noAction) {
						Image(systemName: "line.horizontal.3.decrease.circle")
							.foregroundColor(.gray)

					}.contextMenu {
						Button(action: model.clear) {
							Text("Clear")
							Image(systemName: "bin.xmark")
						}
						Button(action: model.markRead) {
							Text("Mark all as read")
							Image(systemName: "eye.fill")
						}
					}
				}
				#endif
			}

			#if os(macOS)
			if model.parent != nil {
				HStack {
					Text("Topic")
					Spacer()
					Text(model.nameQualified)
						.textSelection(.enabled)
				}
			}
			#endif
		}
	}

	private func noAction() {
		// this function should not execute anything
	}
}
