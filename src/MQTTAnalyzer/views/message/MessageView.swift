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
    @State var postMessagePresented = false
	@State var postMessageFormModel: PostMessageFormModel?

    var body: some View {
        Section(header: Text("Messages")) {
            ForEach(messagesByTopic.messages) {
				MessageCellView(message: $0,
								topic: self.messagesByTopic.topic,
								selectMessage: self.selectMessage)
            }
            .onDelete(perform: messagesByTopic.delete)
        }
		.sheet(isPresented: $postMessagePresented, onDismiss: cancelPostMessageCreation, content: {
            PostMessageFormModalView(closeCallback: self.cancelPostMessageCreation,
                                 root: self.rootModel,
								 model: self.postMessageFormModel!)
        })
    }
	
	func selectMessage(message: Message) {
		self.postMessageFormModel = PostMessageFormModel.of(message: message)
		postMessagePresented = true
	}
	
    func cancelPostMessageCreation() {
        postMessagePresented = false
		postMessageFormModel = nil
    }
}

struct MessageCellView: View {
	@EnvironmentObject var model: RootModel
	
    let message: Message
    let topic: Topic
	let selectMessage: (Message) -> Void

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
				MenuButton(title: "Post message again",
						   systemImage: "paperplane.fill",
						   action: post)
				MenuButton(title: "Post new message",
						   systemImage: "paperplane.fill",
						   action: postManually)
            }
        }
    }
	
    func copy() {
        UIPasteboard.general.string = self.message.data
    }
	
    func post() {
		self.model.post(message: message)
    }
	
    func postManually() {
		selectMessage(message)
    }
}
