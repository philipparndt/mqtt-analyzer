//
//  MessageCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageView: View {
    @ObservedObject var messagesByTopic: MessagesByTopic

    var body: some View {
        Section(header: Text("Messages")) {
            ForEach(messagesByTopic.messages) {
                MessageCellView(message: $0, topic: self.messagesByTopic.topic)
            }
            .onDelete(perform: messagesByTopic.delete)
        }
    }
}

struct MessageCellView: View {
	@EnvironmentObject var model: RootModel
    let message: Message
    let topic: Topic
    @State var postMessagePresented = false

    var body: some View {
        NavigationLink(destination: MessageDetailsView(message: message, topic: topic)) {
            HStack {
                Image(systemName: "radiowaves.right")
                    .font(.subheadline)
                    .foregroundColor(message.isJson() ? .green : .gray)
                
                VStack(alignment: .leading) {
                    Text(message.data)
                        .lineLimit(8)
                    Text(message.localDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .contextMenu {
                Button(action: copy) {
                    Text("Copy message")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: post) {
                    Text("Post message again")
                    Image(systemName: "paperplane.fill")
                }
                Button(action: postManually) {
                    Text("Post new message")
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .sheet(isPresented: $postMessagePresented, onDismiss: cancelPostMessageCreation, content: {
            PostMessageFormModalView(isPresented: self.$postMessagePresented,
                                 root: self.model,
								 model: self.createPostFormModel())
        })
    }
	
	func createPostFormModel() -> PostMessageFormModel {
		var model = PostMessageFormModel()
		model.message = message.data
		model.topic = topic.name
		model.qos = Int(message.qos)
		model.retain = message.retain
		model.json = message.isJson()
		model.jsonData = message.jsonData
		
		if message.isJson() {
			let data = message.jsonData!
			print(data)
			print(message.json(jsonData: data)?.prettyPrintedJSONString ?? "{}")
			
			var properties: [PostMessageProperty] = []
			PostMessageFormModel.createJsonProperties(json: data, path: [], properties: &properties)
			
			properties.forEach { model.properties.append($0) }
		}
		
		return model
	}
	
    func copy() {
        UIPasteboard.general.string = self.message.data
    }
	
    func post() {
		self.model.post(topic: topic, message)
    }
	
    func postManually() {
		postMessagePresented = true
    }
	
    func cancelPostMessageCreation() {
        postMessagePresented = false
    }
}
