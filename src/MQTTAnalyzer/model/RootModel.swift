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
    
    let mqttSession: MQTTSessionController
    let hostsModel: HostsModel
    
    var messageModelByHost: [Host: MessageModel] = [:]
    
    init() {
        hostsModel = HostsModelPersistence.load()
        
        for host in hostsModel.hosts {
            messageModelByHost[host] = MessageModel()
        }

        // FIXME: remove hardcoded session
        let host = hostsModel.hosts[0]
        let model = messageModelByHost[host]!
        mqttSession = MQTTSessionController(host: host, model: model)
    }
 
    func getMessageModel(_ host: Host) -> MessageModel {
        var model = messageModelByHost[host]
        
        if (model == nil) {
            model = MessageModel()
            messageModelByHost[host] = model
        }
        
        return model!
    }
    
}
