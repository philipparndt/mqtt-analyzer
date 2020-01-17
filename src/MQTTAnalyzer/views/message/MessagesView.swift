//
//  MessagesView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
	@ObservedObject var messagesByTopic: MessagesByTopic
	let host: Host
	
	var body: some View {
		VStack(alignment: .leading) {
			List {
				MessageTopicView(messagesByTopic: messagesByTopic)

				DataSeriesView(messagesByTopic: messagesByTopic)
				
				MessageView(messagesByTopic: messagesByTopic, host: host)
			}
		}
		.navigationBarTitle(Text(messagesByTopic.topic.lastSegment))
		.listStyle(GroupedListStyle())
		.onAppear {
			self.messagesByTopic.read.markRead()
		}
	}
	
	func copyTopic() {
		UIPasteboard.general.string = messagesByTopic.topic.name
	}
}
