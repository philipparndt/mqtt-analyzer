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
            VStack(alignment: .leading) {
                Text(host.alias)
                Spacer()
                Group {
                    Text("\(host.hostname)")
                    Text(host.topic)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
    }
}
