//
//  ReconnectView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//


import SwiftUI

struct ReconnectView : View {
    
    @ObjectBinding
    var host : Host
    
    var body: some View {
        Group {
            if (host.connecting) {
                Section(header: Text("Connection")) {
                   HStack {
                       Text("Connecting...")
                   }.foregroundColor(.gray)
                }
            } else if (!host.connected) {
                Section(header: Text("Connection")) {
                   HStack {
                       Image(systemName: "desktopcomputer")
                                           .padding()

                       Button(action: reconnect) {
                           Text("Disconnected")
                       }
                   }.foregroundColor(.red)
                }
            }
        }
    }
    
    func reconnect() {
        self.host.reconnect()
    }
}
