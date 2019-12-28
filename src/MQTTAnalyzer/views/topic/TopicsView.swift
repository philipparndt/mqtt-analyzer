//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsView: View {
    @EnvironmentObject var rootModel: RootModel
    
    @ObservedObject
    var model: MessageModel
    
    @ObservedObject
    var host: Host
  
    var body: some View {
        List {
            ReconnectView(host: self.host)
            
            TopicsToolsView(model: self.model)
            
            Section(header: Text("Topics")) {
                if model.displayTopics.isEmpty {
                    Text("no topics available")
                        .foregroundColor(.secondary)
                }
                else {
                    ForEach(model.displayTopics) { messages in
                        TopicCellView(messages: messages, model: self.model)
                    }
                }
            }
        }
        .navigationBarTitle(Text(host.topic), displayMode: .inline)
        .listStyle(GroupedListStyle())
        .onAppear {
            self.rootModel.connect(to: self.host)
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
