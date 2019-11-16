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
                
                QuickFilterView(searchFilter: self.$searchFilter)
            }
            
            Section(header: Text("Topics")) {
                ForEach(Array(model.sortedTopicsByFilter(filter: searchFilter))) { messages in
                    MessageGroupCell(messages: messages, searchFilter: self.$searchFilter)
                    }
                    .onDelete(perform: model.delete)
            }
        }
        .navigationBarTitle(Text(host.topic), displayMode: .inline)
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
    
    @Binding
    var searchFilter : String
    
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
                    Text("\(messages.messages.count) messages")
                        .font(.subheadline)
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
        self.searchFilter = self.messages.topic.name
    }
    
    func focusParent() {
        self.searchFilter = self.messages.topic.name.pathUp()
    }
}

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
