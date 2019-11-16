//
//  MQTTController.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine
import Moscapsule

class MQTTSessionController {
    
    let model : MessageModel
    let host : Host
    
    var mqtt: MQTTClient!
    
    var connected: Bool = false
    
    init(host: Host, model: MessageModel) {
        self.model = model
        self.host = host
        
        self.host.reconnectDelegate = reconnect
    }
    
    deinit {
        host.connected = false
        print("MQTTController deinit")
    }
    
    func reconnect() {
        mqtt.reconnect()
    }
    
    func connect() {
        if (connected) {
            reconnect()
        }
        else {
            establishConnection(host)
            connected = true
        }
    }
    
    func disconnect() {
        mqtt.disconnect()
        connected = false
        mqtt = nil
    }
    
    func establishConnection(_ host: Host) {
        let mqttConfig = MQTTConfig(clientId: clientID(), host: host.hostname, port: host.port, keepAlive: 60)
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Connected. Return Code is \(returnCode.description)")
            DispatchQueue.main.async {
                host.connected = true
            }
        }
        mqttConfig.onDisconnectCallback = { returnCode in
           NSLog("Disconnected. Return Code is \(returnCode.description)")
            DispatchQueue.main.async {
                host.connected = false
            }
       }
        
        mqttConfig.onMessageCallback = { mqttMessage in
            DispatchQueue.main.async {
                let messageString = mqttMessage.payloadString ?? "";
                           NSLog("MQTT receive. \(messageString)")
                let msg = Message(data: messageString, date: Date(), qos: mqttMessage.qos)
                           self.model.append(topic: mqttMessage.topic, message: msg)
            }
        }
        
        // create new MQTT Connection
        mqtt = MQTT.newConnection(mqttConfig)

        subscribeToChannel(host)
    }
    
    func subscribeToChannel(_ host: Host) {
        mqtt.subscribe(host.topic, qos: 2)
    }
    
    
    // MARK: - Utilities
    
    func clientID() -> String {
        let userDefaults = UserDefaults.standard
        let clientIDPersistenceKey = "clientID"
        let clientID: String

        if let savedClientID = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
            clientID = savedClientID
        } else {
            clientID = "MQTTAnalyzer_" + randomStringWithLength(10)
            userDefaults.set(clientID, forKey: clientIDPersistenceKey)
            userDefaults.synchronize()
        }

        return clientID
    }
    
    // http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    func randomStringWithLength(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
