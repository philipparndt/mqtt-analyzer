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
	var messages: TopicTree
	var model: TopicTree
	@Binding var publishMessagePresented: Bool
	
	let host: Host
	let selectMessage: (Message) -> Void
	
	var body: some View {
		NavigationLink(destination: MessagesView(leaf: messages, host: host)) {
			HStack {
				ReadMarkerView(read: messages.read)
				
				VStack(alignment: .leading) {
					Text(messages.nameQualified)
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
				
				MenuButton(title: "Publish message again", systemImage: "paperplane.fill", action: publish)
				MenuButton(title: "Publish new message", systemImage: "paperplane.fill", action: publishManually)
			}
		}
	}
	
	func publish() {
		if let first = messages.messages.last {
			// FIXME: implement
			//root.publish(message: first, on: host)
		}
	}
	
	func publishManually() {
		if let first = messages.messages.last {
			// FIXME: implement
//			selectMessage(first)
//			publishMessagePresented = true
		}
	}
	
	func messagePreview() -> String {
		return messages.messages.last?.payload.dataString ?? "<no message>"
	}
	
	func copyTopic() {
		UIPasteboard.general.string = messages.nameQualified
	}
	
	func copyMessage() {
		UIPasteboard.general.string = messages.messages.last?.payload.dataString ?? ""
	}
	
	func focus() {
		// FIXME Implement this
		// model.setFilterImmediatelly(messages.topic.name)
	}
	
	func focusParent() {
		// FIXME: implement
		// model.setFilterImmediatelly(messages.topic.name.pathUp())
	}
}
