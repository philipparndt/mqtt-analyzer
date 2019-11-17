//
//  TopicCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicCellView : View {
    @ObservedObject
    var messages: MessagesByTopic
    
    @ObservedObject
    var model : MessageModel
    
    var body: some View {
        NavigationLink(destination: MessagesView(messagesByTopic: messages)) {
            HStack {
                ReadMarkerView(read: messages.read)
                
                VStack (alignment: .leading) {
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
                Button(action: copy) {
                    Text("Copy topic")
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
            }
        }
    }
    
    func messagePreview() -> String {
        return self.messages.getFirst()
    }
    
    func copy() {
        UIPasteboard.general.string = self.messages.topic.name
    }
    
    func focus() {
        self.model.filter = self.messages.topic.name
    }
    
    func focusParent() {
        self.model.filter = self.messages.topic.name.pathUp()
    }
}
