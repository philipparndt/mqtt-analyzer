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
	@Binding var publishMessagePresented: Bool
	
	let host: Host
	let selectMessage: (MsgMessage) -> Void
	@State private var selection: String?

	var body: some View {
		NavigationLink(destination: MessagesView(node: messages, host: host), tag: messages.nameQualified, selection: $selection) {
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
				
				Menu {
					MenuButton(title: "Message again", systemImage: "paperplane.fill", action: publish)
					MenuButton(title: "New message", systemImage: "paperplane.fill", action: publishManually)
						.accessibilityLabel("publish new")
				} label: {
					Label("Publish", systemImage: "paperplane.fill")
				}
				.accessibilityLabel("publish")
				
				Menu {
					DestructiveMenuButton(title: "Delete retained message from broker", systemImage: "trash.fill", action: deleteRetained)
						.accessibilityLabel("confirm-delete-retained")
				} label: {
					Label("Delete", systemImage: "trash.fill")
				}
				.accessibilityLabel("delete-retained")
			}
		}
		.accessibilityLabel("group: \(messages.nameQualified)")
	}
	
	func publish() {
		if let first = messages.messages.first {
			root.publish(message: first, on: host)
		}
	}
	
	func deleteRetained() {
		if let first = messages.messages.first {
			root.publish(message: MsgMessage(
				topic: first.topic,
				payload: MsgPayload(data: []),
				metadata: MsgMetadata(qos: first.metadata.qos, retain: true)), on: host)
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
