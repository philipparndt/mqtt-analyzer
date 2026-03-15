//
//  MessagesView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
	@ObservedObject var node: TopicTree
	let host: Host

	/// Skip data series for payloads larger than 50KB
	private let dataSeriesSizeThreshold = 50_000

	private var shouldShowDataSeries: Bool {
		guard let lastMessage = node.messages.last else { return true }
		return lastMessage.payload.size <= dataSeriesSizeThreshold
	}

	var body: some View {
		VStack(alignment: .leading) {
			List {
				MessageTopicView(node: node)

				if shouldShowDataSeries {
					DataSeriesView(topic: node.nameQualified, series: node.timeSeries)
				} else if node.timeSeries.hasTimeseries {
					DataSeriesSkippedView()
				}

				MessageView(node: node, host: host)
			}
			.accessibilityIdentifier("messages-list")
		}
		#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
		.navigationTitle(node.name)
		#if os(iOS)
		.listStyle(.insetGrouped)
		#endif
		.onAppear {
			self.node.markRead()
		}
	}

	func copyTopic() {
		Pasteboard.copy(node.nameQualified)
	}
}
