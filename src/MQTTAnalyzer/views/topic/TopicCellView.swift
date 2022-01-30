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
	let selectMessage: (MsgMessage) -> Void
	
	var body: some View {
		NavigationLink(destination: MessagesView(node: messages, host: host)) {
			HStack {
				ReadMarkerView(read: messages.readState)
				
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
								
				MenuButton(title: "Publish message again", systemImage: "paperplane.fill", action: publish)
				MenuButton(title: "Publish new message", systemImage: "paperplane.fill", action: publishManually)
			}
		}
	}
	
	func publish() {
		if let first = messages.messages.first {
			root.publish(message: first, on: host)
		}
	}
	
	func publishManually() {
		if let first = messages.messages.first {
			selectMessage(first)
			publishMessagePresented = true
		}
	}
	
	func messagePreview() -> String {
		return messages.messages.first?.payload.dataString ?? "<no message>"
	}
	
	func copyTopic() {
		UIPasteboard.general.string = messages.nameQualified
	}
	
	func copyMessage() {
		UIPasteboard.general.string = messages.messages.first?.payload.dataString ?? ""
	}
	
}
