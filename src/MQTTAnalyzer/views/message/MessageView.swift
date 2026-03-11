//
//  MessageCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageView: View {
	@EnvironmentObject var rootModel: RootModel

	@ObservedObject var node: TopicTree
	@StateObject var publishMessageFormModel = PublishMessageFormModel()

	let host: Host

	var body: some View {
		Section(header: Text("Messages")) {
			ForEach(node.messages) {
				MessageCellView(message: $0,
								selectMessage: self.selectMessage,
								host: self.host)
					.sheet(isPresented: $publishMessageFormModel.isPresented, onDismiss: cancelPublishMessageCreation, content: {
						PublishMessageFormModalView(closeCallback: self.cancelPublishMessageCreation,
							 root: self.rootModel,
							 host: self.host,
							 model: self.publishMessageFormModel)
					})
					.accessibilityIdentifier("message")
			}
			.onDelete(perform: node.delete)
		}
	}
	
	func selectMessage(message: MsgMessage) {
		publishMessageFormModel.topic = message.topic.nameQualified
		publishMessageFormModel.message = message.payload.dataString
		publishMessageFormModel.qos = Int(message.metadata.qos)
		publishMessageFormModel.retain = message.metadata.retain
		publishMessageFormModel.isPresented = true
	}
	
	func cancelPublishMessageCreation() {
		self.publishMessageFormModel.isPresented = false
	}
}

struct MessageCellView: View {
	@EnvironmentObject var model: RootModel
	
	let message: MsgMessage
	let selectMessage: (MsgMessage) -> Void
	let host: Host
	
	var body: some View {
		NavigationLink(destination: MessageDetailsView(message: message, host: host)) {
			HStack {
				Image(systemName: "radiowaves.right")
					.font(.subheadline)
					.foregroundColor(message.payload.isJSON ? .green : .gray)

				VStack(alignment: .leading) {
					AnsiTextView(text: message.payload.dataString, lineLimit: 8)
					Text(message.metadata.localDate)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
			.contextMenu {
				MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
				MenuButton(title: "Copy recent message", systemImage: "doc.on.doc", action: copyMessage)
				
				Menu {
					MenuButton(title: "Message again", systemImage: "paperplane.fill", action: publish)
					MenuButton(title: "New message", systemImage: "paperplane.fill", action: publishManually)
						.accessibilityIdentifier("publish new")
				} label: {
					Label("Publish", systemImage: "paperplane.fill")
				}
				.accessibilityIdentifier("publish")
				
				Menu {
					DestructiveMenuButton(title: "Delete retained message from broker", systemImage: "trash.fill", action: deleteRetained)
						.accessibilityIdentifier("confirm-delete-retained")
				} label: {
					Label("Delete", systemImage: "trash.fill")
				}
				.accessibilityIdentifier("delete-retained")
			}
		}
	}
	
	func copyTopic() {
		Pasteboard.copy(message.topic.nameQualified)
	}
	
	func copyMessage() {
		Pasteboard.copy(message.payload.dataString)
	}
	
	func publish() {
		model.publish(message: message, on: host)
	}
	
	func publishManually() {
		selectMessage(message)
	}
	
	func deleteRetained() {
		model.publish(message: MsgMessage(
			topic: message.topic,
			payload: MsgPayload(data: []),
			metadata: MsgMetadata(qos: message.metadata.qos, retain: true)), on: host)
	}
}
