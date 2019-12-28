//
//  NewHostFormModalView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import swift_petitparser

// MARK: Create Host
struct NewHostFormModalView: View {
    @Binding var isPresented: Bool
    let root: RootModel
    var hosts: HostsModel
    
    @State private var host: HostFormModel = HostFormModel()
    @State private var auth: Bool = false
    
    var body: some View {
        NavigationView {
            EditHostFormView(host: $host, auth: $auth)
                .font(.caption)
                .navigationBarTitle(Text("New host"))
                .navigationBarItems(
                    leading: Button(action: cancel) {
                        Text("Cancel")
                        
                    }.buttonStyle(ActionStyleLeading()),
                    trailing: Button(action: save) {
                        Text("Save")
                    }.buttonStyle(ActionStyleTrailing())
            )
        }
    }
    
    func save() {
        let newHost =  Host()
        newHost.alias = host.alias
        newHost.hostname = host.hostname
        newHost.qos = host.qos
        newHost.auth = self.auth
        newHost.port = Int32(host.port) ?? 1883
        newHost.topic = host.topic
        
        let ip1 = NumbersParser
            .int(from: 1, to: 255)
            .seq(CharacterParser.of(".")
                .seq(NumbersParser.int(from: 0, to: 255)))
            .times(3).trim().flatten()
        
        let host1 = CharacterParser.anyOf("a-zA-Z0-9.").plus()
            .trim().flatten()

        let server = ip1.or(host1)
        
        let result = server.parse(newHost.hostname)
        print(result)
        
        if self.auth {
            newHost.username = host.username
            newHost.password = host.password
        }
        
        hosts.hosts.append(newHost)
        
        root.persistence.create(newHost)
        
        self.isPresented = false
        clear()
    }
    
    func cancel() {
        self.isPresented = false
        clear()
    }
    
    func clear() {
        host = HostFormModel()
        auth = false
    }
}
