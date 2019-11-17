//
//  HostCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostCellView : View {
    var host: Host
    @EnvironmentObject var model : RootModel

    var messageModel: MessageModel
    
    var body: some View {
        NavigationLink(destination: TopicsView(model: messageModel, host: host)) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(host.connected ? .green : .red)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text(host.alias)
                    .font(.title)
                    .padding([.bottom])
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("hostname:")
                                .disableAutocorrection(true)
                            Text("topic:")
                                .disableAutocorrection(true)
                        }.foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text("\(host.hostname)")
                            Text(host.topic)
                        }
                    }
                }
            }
        }
    }
}
