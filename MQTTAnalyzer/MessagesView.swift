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
        NavigationButton(destination: MessageDetailsView(message: message, topic: topic)) {
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

struct ChartCell : View {
    var path : String

    var body: some View {
        NavigationButton(destination: ChartDetailsView(title: path)) {
            HStack {
                Image(systemName: "chart.bar")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                VStack (alignment: .leading) {
                    Text(path)
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
                    ChartCell(path: "temperature")
                }
                
                Section(header: Text("Messages")) {
                    ForEach(messagesByTopic.messages) { message in
                        MessageCell(message: message, topic: self.messagesByTopic.topic)
                    }
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
