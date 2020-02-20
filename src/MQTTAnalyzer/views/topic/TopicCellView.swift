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
	
	let host: Host
	let selectMessage: (Message) -> Void
	
	var body: some View {
		NavigationLink(destination: MessagesView(messagesByTopic: messages, host: host)) {
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
		if let first = messages.getRecentMessage() {
			root.post(message: first, on: host)
		}
	}
	
	func postManually() {
		if let first = messages.getRecentMessage() {
			selectMessage(first)
			postMessagePresented = true
		}
	}
	
	func messagePreview() -> String {
		return messages.getRecent()
	}
	
	func copyTopic() {
		UIPasteboard.general.string = messages.topic.name
	}
	
	func copyMessage() {
		UIPasteboard.general.string = messages.getRecent()
	}
	
	func focus() {
		model.setFilterImmediatelly(messages.topic.name)
	}
	
	func focusParent() {
		model.setFilterImmediatelly(messages.topic.name.pathUp())
	}
}
