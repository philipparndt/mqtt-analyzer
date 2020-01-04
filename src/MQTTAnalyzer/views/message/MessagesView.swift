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
	
	var body: some View {
		VStack(alignment: .leading) {
			List {
				MessageTopicView(messagesByTopic: messagesByTopic)

				DataSeriesView(messagesByTopic: messagesByTopic)
				
				MessageView(messagesByTopic: messagesByTopic)
			}
		}
		.navigationBarTitle(Text(messagesByTopic.topic.lastSegment))
		.listStyle(GroupedListStyle())
		.onAppear {
			self.messagesByTopic.read.markRead()
			print("MessagesView appeared!")
		}.onDisappear {
			print("MessagesView disappeared!")
		}
	}
	
	func copyTopic() {
		UIPasteboard.general.string = self.messagesByTopic.topic.name
	}
}

#if DEBUG
//struct MessagesView_Previews : PreviewProvider {
//	static var previews: some View {
//		NavigationView {
//			MessagesView(messagesByTopic : MessageModel().messagesByTopic[0])
//		}
//	}
//}
#endif
