//
//  MessagesView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
	@ObservedObject var leaf: TopicTree
	let host: Host
	
	var body: some View {
		VStack(alignment: .leading) {
			List {
				MessageTopicView(leaf: leaf)

				DataSeriesView(leaf: leaf)

				MessageView(leaf: leaf, host: host)
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle(leaf.name)
		.listStyle(GroupedListStyle())
		.onAppear {
			self.leaf.read.markRead()
		}
	}
	
	func copyTopic() {
		UIPasteboard.general.string = leaf.nameQualified
	}
}
