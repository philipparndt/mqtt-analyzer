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
                    Text(message.data)
                    Text(message.localDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ChartsCell : View {
    let path : DiagramPath
    @ObjectBinding var messagesByTopic: MessagesByTopic

    var body: some View {
        NavigationLink(destination: ChartDetailsView(path: path, messagesByTopic: messagesByTopic)) {
            HStack {
                Image(systemName: "chart.bar")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                VStack (alignment: .leading) {
                    Text(path.path)
                }
            }
        }
    }
}

struct MessagesView : View {
    @ObjectBinding var messagesByTopic: MessagesByTopic
    
    var body: some View {
        VStack (alignment: .leading) {
            List {
                Section(header: Text("Topic")) {
                    Text(messagesByTopic.topic.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Section(header: Text("Diagrams")) {
                    ForEach(messagesByTopic.getDiagrams()) {
                        ChartsCell(path: $0, messagesByTopic: self.messagesByTopic)
                    }
                }
                
                Section(header: Text("Messages")) {
                    ForEach(messagesByTopic.messages) { MessageCell(message: $0, topic: self.messagesByTopic.topic) }
                    .onDelete(perform: messagesByTopic.delete)
                }
            }
        }
        .navigationBarTitle(Text(messagesByTopic.topic.lastSegment))
        .listStyle(.grouped)
            .onAppear {
                self.messagesByTopic.markRead()
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
