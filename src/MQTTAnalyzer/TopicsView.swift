//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsView : View {
    @EnvironmentObject var rootModel : RootModel
    
    @ObservedObject
    var model : MessageModel
    
    @ObservedObject
    var host : Host
    
    @State
    private var searchFilter : String = ""
    
    var body: some View {
        List {
            ReconnectView(host: self.host)
            
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
                
//                TextField("Search", text: $searchFilter)
            }
            
            Section(header: Text("Topics")) {
                ForEach(Array(model.sortedTopicsByFilter(filter: searchFilter))) { messages in
                    MessageGroupCell(messages: messages)
                    }
                    .onDelete(perform: model.delete)
            }
        }
        .navigationBarTitle(Text(host.topic), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
        .listStyle(GroupedListStyle())
        .onAppear {
            self.rootModel.connect(to: self.host)
        }
    }
    
    func reconnect() {
        self.host.reconnect()
    }
}

struct MessageGroupCell : View {
    @ObservedObject
    var messages: MessagesByTopic
    
    var body: some View {
        NavigationLink(destination: MessagesView(messagesByTopic: messages)) {
            HStack {
                Group {
                    if (messages.read) {
//                        Image(uiImage: UIImage(named: "empty")!)
//                        .font(.subheadline)
//                        .foregroundColor(.blue)
                        Spacer()
                            .fixedSize()
                            .frame(width: 23, height: 23)
                    }
                    else {
                        Image(systemName: "circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .scaleEffect(messages.read ? 0 : 1)
                .animation(.easeInOut)
                
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
