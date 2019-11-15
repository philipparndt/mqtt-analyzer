//
//  x.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine

class RootModel: ObservableObject {
    var willChange = PassthroughSubject<RootModel, Never>()
    
    var sessions: [Host: MQTTSessionController] = [:]
    let hostsModel: HostsModel
    
    var messageModelByHost: [Host: MessageModel] = [:]
    
    init() {
        hostsModel = HostsModelPersistence.load()
        
        for host in hostsModel.hosts {
            messageModelByHost[host] = MessageModel()
        }
    }
 
    func getMessageModel(_ host: Host) -> MessageModel {
        var model = messageModelByHost[host]
        
        if (model == nil) {
            model = MessageModel()
            messageModelByHost[host] = model
        }
        
        return model!
    }
    
    func connect(to: Host) {
        print("Connecting to " + to.hostname)
        
        var session = sessions[to]
        if (session == nil) {
            let model = messageModelByHost[to]
            if (model != nil) {
                session = MQTTSessionController(host: to, model: model!)
                sessions[to] = session
            }
        }
        
        session?.connect()
    }
    
}
