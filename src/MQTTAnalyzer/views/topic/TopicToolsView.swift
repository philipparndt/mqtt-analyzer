//
//  TopicToolsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsToolsView: View {
    @ObservedObject
    var model: MessageModel
        
    var body: some View {
        Section {
            HStack {
                Text("Topics/Messages")
                Spacer()
                Text("\(model.messagesByTopic.count)/\(model.messageCount)")
                
                Button(action: model.readall) {
                    Button(action: noAction) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(.gray)
                            
                    }.contextMenu {
                        Button(action: model.clear) {
                            Text("Delete all")
                            Image(systemName: "bin.xmark")
                        }
                        Button(action: model.readall) {
                            Text("Mark all as read")
                            Image(systemName: "eye.fill")
                        }
                    }
                }
            }
         
            QuickFilterView(model: self.model)
        }
    }
    
    private func noAction() {
        
    }
}
