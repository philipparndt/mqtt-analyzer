//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import SwiftUICharts

struct TopicsView : View {
    @ObjectBinding
    var model : MessageModel
    
    var body: some View {
        List {
            Section {
                ForEach(Array(model.sortedTopics())) { messages in
                    MessageGroupCell(messages: messages)
                    }
                    .onDelete(perform: model.delete)
            }
            }
            .navigationBarTitle(Text("home/#"))
            .navigationBarItems(trailing: EditButton())
            .listStyle(.grouped)
    }
}

struct MessageGroupCell : View {
    var messages: MessagesByTopic
    
    var body: some View {
        NavigationButton(destination: MessagesView(messagesByTopic: messages)) {
            VStack (alignment: .leading) {
                Text(messages.topic.name)
                Text("\(messages.messages.count) messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
