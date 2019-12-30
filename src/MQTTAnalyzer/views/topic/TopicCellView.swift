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
	@State private var postMessagePresented = false

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
                Button(action: copyTopic) {
                    Text("Copy topic")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: copyMessage) {
                    Text("Copy recent message")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: focus) {
                    Text("Focus on")
                    Image(systemName: "eye.fill")
                }
                Button(action: focusParent) {
                    Text("Focus on parent")
                    Image(systemName: "eye.fill")
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
                                 root: self.root,
								 model: self.createPostFormModel())
        })
    }
	
	func createPostFormModel() -> PostMessageFormModel {
		if let first = self.messages.getFirstMessage() {
			return PostMessageFormModel.of(message: first, topic: self.messages.topic)
		}
		return PostMessageFormModel()
	}
	
    func post() {
		if let first = self.messages.getFirstMessage() {
			self.root.post(topic: self.messages.topic, first)
		}
	}
	
    func postManually() {
		postMessagePresented = true
    }
	
    func cancelPostMessageCreation() {
        postMessagePresented = false
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
