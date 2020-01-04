//
//  TopicCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicCellView: View {
	@EnvironmentObject var root: RootModel
	@ObservedObject var messages: MessagesByTopic
	@ObservedObject var model: MessageModel
	@Binding var postMessagePresented: Bool
	
	let selectMessage: (Message) -> Void
	
	var body: some View {
		NavigationLink(destination: MessagesView(messagesByTopic: messages)) {
			HStack {
				ReadMarkerView(read: messages.read)
				
				VStack(alignment: .leading) {
					Text(messages.topic.name)
					Text(messagePreview())
						.font(.subheadline)
						.foregroundColor(.secondary)
						.lineLimit(8)
					Spacer()
					Text("\(messages.messages.count) message\(messages.messages.count == 1 ? "" : "s")")
						.font(.footnote)
						.foregroundColor(.secondary)
				}
			}
			.contextMenu {
				MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
				MenuButton(title: "Copy recent message", systemImage: "doc.on.doc", action: copyMessage)
				
				MenuButton(title: "Focus on", systemImage: "eye.fill", action: focus)
				MenuButton(title: "Focus on parent", systemImage: "eye.fill", action: focusParent)
				
				MenuButton(title: "Post message again", systemImage: "paperplane.fill", action: post)
				MenuButton(title: "Post new message", systemImage: "paperplane.fill", action: postManually)
			}
		}
	}
	
	func post() {
		if let first = self.messages.getFirstMessage() {
			self.root.post(message: first)
		}
	}
	
	func postManually() {
		if let first = self.messages.getFirstMessage() {
			selectMessage(first)
			postMessagePresented = true
		}
	}
	
	func messagePreview() -> String {
		return self.messages.getFirst()
	}
	
	func copyTopic() {
		UIPasteboard.general.string = self.messages.topic.name
	}
	
	func copyMessage() {
		UIPasteboard.general.string = self.messages.getFirst()
	}
	
	func focus() {
		self.model.setFilterImmediatelly(self.messages.topic.name)
	}
	
	func focusParent() {
		self.model.setFilterImmediatelly(self.messages.topic.name.pathUp())
	}
}
