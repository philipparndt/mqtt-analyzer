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

	@ObservedObject var messagesByTopic: MessagesByTopic
	@State var publishMessagePresented = false
	@State var publishMessageFormModel: PublishMessageFormModel?
	let host: Host

	var body: some View {
		Section(header: Text("Messages")) {
			ForEach(messagesByTopic.messages) {
				MessageCellView(message: $0,
								topic: self.messagesByTopic.topic,
								selectMessage: self.selectMessage,
								host: self.host)
			}
			.onDelete(perform: messagesByTopic.delete)
		}
		.sheet(isPresented: $publishMessagePresented, onDismiss: cancelPublishMessageCreation, content: {
			PublishMessageFormModalView(closeCallback: self.cancelPublishMessageCreation,
								 root: self.rootModel,
								 host: self.host,
								 model: self.publishMessageFormModel!)
		})
	}
	
	func selectMessage(message: Message) {
		self.publishMessageFormModel = PublishMessageFormModel.of(message: message)
		publishMessagePresented = true
	}
	
	func cancelPublishMessageCreation() {
		publishMessagePresented = false
		publishMessageFormModel = nil
	}
}

struct MessageCellView: View {
	@EnvironmentObject var model: RootModel
	
	let message: Message
	let topic: Topic
	let selectMessage: (Message) -> Void
	let host: Host
	
	var body: some View {
		NavigationLink(destination: MessageDetailsView(message: message, topic: topic)) {
			HStack {
				Image(systemName: "radiowaves.right")
					.font(.subheadline)
					.foregroundColor(message.isJson() ? .green : .gray)
				
				VStack(alignment: .leading) {
					Text(message.data)
						.lineLimit(8)
					Text(message.localDate)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
			.contextMenu {
				MenuButton(title: "Copy message",
						   systemImage: "doc.on.doc",
						   action: copy)
				MenuButton(title: "Publish message again",
						   systemImage: "paperplane.fill",
						   action: publish)
				MenuButton(title: "Publish new message",
						   systemImage: "paperplane.fill",
						   action: publishManually)
			}
		}
	}
	
	func copy() {
		UIPasteboard.general.string = message.data
	}
	
	func publish() {
		model.publish(message: message, on: host)
	}
	
	func publishManually() {
		selectMessage(message)
	}
}
