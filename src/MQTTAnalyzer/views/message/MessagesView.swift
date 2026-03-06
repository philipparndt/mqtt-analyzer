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
	
	var body: some View {
		VStack(alignment: .leading) {
			List {
				MessageTopicView(node: node)

				DataSeriesView(topic: node.nameQualified, series: node.timeSeries)

				MessageView(node: node, host: host)
			}
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
