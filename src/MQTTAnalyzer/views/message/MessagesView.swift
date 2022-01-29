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

				DataSeriesView(node: node)

				MessageView(node: node, host: host)
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle(node.name)
		.listStyle(GroupedListStyle())
		.onAppear {
			self.node.read.markRead()
		}
	}
	
	func copyTopic() {
		UIPasteboard.general.string = node.nameQualified
	}
}
