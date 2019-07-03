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
            Section(header: Text("Tools")) {
                HStack {
                    Text("Topics")
                    Spacer()
                    Text(String(model.messagesByTopic.count))
                }
                HStack {
                    Text("Messages")
                    Spacer()
                    Text(String(model.countMessages()))
                }
                
                Button(action: model.readall) {
                    Text("Read all")
                }
            }
            
            Section(header: Text("Topics")) {
                ForEach(Array(model.sortedTopics())) { messages in
                    MessageGroupCell(messages: messages)
                    }
                    .onDelete(perform: model.delete)
            }
        }
        .navigationBarTitle(Text("home/#"), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .listStyle(.grouped)
    }
}

struct MessageGroupCell : View {
    @ObjectBinding
    var messages: MessagesByTopic
    
    var body: some View {
        NavigationLink(destination: MessagesView(messagesByTopic: messages)) {
            HStack {
                messages.read ?
                    Image(systemName: "circle")
                        .font(.subheadline)
                        .foregroundColor(.white)
                : Image(systemName: "circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                VStack (alignment: .leading) {
                    Text(messages.topic.name)
                    Text(messages.getFirst()).font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(messages.messages.count) messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
