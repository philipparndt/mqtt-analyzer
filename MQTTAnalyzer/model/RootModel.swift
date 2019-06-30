//
//  x.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine

class RootModel: BindableObject {
    var didChange = PassthroughSubject<RootModel, Never>()
    
    let mqttSession: MQTTSessionController
    let hostsModel: HostsModel
    
    var messageModelByHost: [Host: MessageModel] = [:]
    
    init() {
        hostsModel = HostsModel.sampleModel()
        let host = hostsModel.hosts[0]
        let model = MessageModel()
        
        messageModelByHost[host] = model
        
        mqttSession = MQTTSessionController(host: host, model: model)
    }
    
}
