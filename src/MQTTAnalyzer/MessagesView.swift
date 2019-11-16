//
//  MessagesView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageCell : View {
    let message: Message
    let topic: Topic
    
    var body: some View {
        NavigationLink(destination: MessageDetailsView(message: message, topic: topic)) {
            HStack {
                Image(systemName: "radiowaves.right")
                    .font(.subheadline)
                    .foregroundColor(message.isJson() ? .green : .gray)
                
                VStack (alignment: .leading) {
                    Text(messagePreview())
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
            }
        }
    }
    
    func messagePreview() -> String {
        return self.message.data.trunc(length: 500)
    }
    
    func copy() {
        UIPasteboard.general.string = self.message.data
    }
}

struct ChartsCell : View {
    let path : DiagramPath
    @ObservedObject var messagesByTopic: MessagesByTopic

    var body: some View {
        NavigationLink(destination: ChartDetailsView(path: path, messagesByTopic: messagesByTopic)) {
            HStack {
                Image(systemName: "chart.bar")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text(path.path)
                
                Spacer()
                
                Text(lastValue().stringValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    func lastValue() -> NSNumber {
        let last = self.messagesByTopic.getTimeSeriesLastValue(self.path)
        return last.map { $0.num } ?? 0
    }
}

struct MessagesView : View {
    @ObservedObject var messagesByTopic: MessagesByTopic
    
    var body: some View {
        VStack (alignment: .leading) {
            List {
                Section(header: Text("Topic")) {
                    Text(messagesByTopic.topic.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if (messagesByTopic.hasDiagrams()) {
                    Section(header: Text("Diagrams")) {
                        ForEach(messagesByTopic.getDiagrams()) {
                            ChartsCell(path: $0, messagesByTopic: self.messagesByTopic)
                        }
                    }
                }
                
                Section(header: Text("Messages")) {
                    ForEach(messagesByTopic.messages) { MessageCell(message: $0, topic: self.messagesByTopic.topic) }
                    .onDelete(perform: messagesByTopic.delete)
                }
            }
        }
        .navigationBarTitle(Text(messagesByTopic.topic.lastSegment))
        .listStyle(GroupedListStyle())
        .onAppear {
            self.messagesByTopic.read.markRead()
            print("MessagesView appeared!")
        }.onDisappear {
            print("MessagesView disappeared!")
        }
    }
}

#if DEBUG
//struct MessagesView_Previews : PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            MessagesView(messagesByTopic : MessageModel().messagesByTopic[0])
//        }
//    }
//}
#endif
