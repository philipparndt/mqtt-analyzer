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
	@State var publishMessageFormModel = PublishMessageFormModel()

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
											 model: self.$publishMessageFormModel)
					})
			}
			.onDelete(perform: node.delete)
		}
	}
	
	func selectMessage(message: MsgMessage) {
		self.publishMessageFormModel = of(message: message)
		self.publishMessageFormModel.isPresented = true
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
		NavigationLink(destination: MessageDetailsView(message: message)) {
			HStack {
				Image(systemName: "radiowaves.right")
					.font(.subheadline)
					.foregroundColor(message.payload.isJSON ? .green : .gray)
				
				VStack(alignment: .leading) {
					Text(message.payload.dataString)
						.lineLimit(8)
					Text(message.metadata.localDate)
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
		UIPasteboard.general.string = message.payload.dataString
	}
	
	func publish() {
		model.publish(message: message, on: host)
	}
	
	func publishManually() {
		selectMessage(message)
	}
}
