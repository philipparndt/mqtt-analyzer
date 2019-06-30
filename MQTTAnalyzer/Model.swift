//
//  MessagesByTopic.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-23.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class MessagesByTopic : Identifiable, BindableObject {
    let topic: Topic
    var messages: [Message] {
        didSet {
            didChange.send()
        }
    }
    
    var didChange = PassthroughSubject<Void, Never>()

    init(topic: Topic, messages: [Message]) {
        self.topic = topic
        self.messages = messages
    }

    func delete(at offsets: IndexSet) {
        // TODO how to remove all?
        messages.remove(at: offsets.first!)
    }

    func debugAddMessage() {
        messages.insert(Message(data: "some data", date: Date()), at: 0)
    }
}

class Message : Identifiable {
    let data : String
    let date : Date
    let dateString : String
    
    let jsonData : [Dictionary<String, Any>]?
    
    init(data: String, date : Date) {
        self.data = data
        self.date = date;
        self.jsonData = Message.toJson(messageData: data)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateString = dateFormatter.string(from: date)
    }
    
    func localDate() -> String {
        return dateString
    }
    
    func isJson() -> Bool {
        return jsonData != nil
    }
    
    func prettyJson() -> String {
        return String(data: try! JSONSerialization.data(withJSONObject: jsonData as Any, options: .prettyPrinted), encoding: .utf8)!
    }
    
    class func toJson(messageData : String) -> [Dictionary<String, Any>]? {
        let data = "[\(messageData)]".data(using: .utf8)!
        do {
            return try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>]
        } catch _ as NSError {
            return nil
        }
    }
}


class Topic : Hashable {
    let name : String
    let lastSegment : String

    init(name: String) {
        self.name = name
        self.lastSegment = Topic.lastSegment(of: name)
    }

    class func lastSegment(of: String) -> String {
        let index = of.lastIndex(of: "/")
            .map { $0.utf16Offset(in: of) }
            .map { $0 + 1 }
        
        return String(of.dropFirst(index ?? 0))
    }
    
    static func == (lhs: Topic, rhs: Topic) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class MessageModel : BindableObject {

    var messagesByTopic: [MessagesByTopic] {
        didSet { didChange.send() }
    }
    
    var didChange = PassthroughSubject<Void, Never>()
    
    init(messagesByTopic: [MessagesByTopic] = []) {
        self.messagesByTopic = messagesByTopic
    }
    
    func delete(at offsets: IndexSet) {
        // TODO how to remove all?
        messagesByTopic.remove(at: offsets.first!)
    }
    
    class func sampleModel() -> MessageModel {
        let vl = Topic(name: "haus/ug/heizung/solar_vl")
        let rl = Topic(name: "haus/ug/heizung/solar_rl")
        
        let result = MessageModel()

        var messagesByTopic : [MessagesByTopic] = []
        messagesByTopic.append(MessagesByTopic(topic: vl, messages: [
            Message(data: "{\"temperature\": 59.3125 }", date: Date()),
            Message(data: "{\"temperature\": 58.125 }", date: Date()),
            Message(data: "{\"temperature\": 56.125 }", date: Date()),
            Message(data: "{\"temperature\": 57.3125 }", date: Date()),
            Message(data: "{\"temperature\": 62.0 }", date: Date()),
            Message(data: "{\"temperature\": 58.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(timeIntervalSince1970: 1415637900))
            ]))
        
        messagesByTopic.append(MessagesByTopic(topic: rl, messages: [
            Message(data: "{\"temperature\": 59.3125 }", date: Date())
            ]))
        
        result.messagesByTopic = messagesByTopic;
        return result
    }
}

class Host : Identifiable {
    var alias : String = ""
    var hostname : String = ""
    var port : UInt16 = 1883
    var topic : String = "#"
    
    var qos : Int = 0
    
    var auth : Bool = false
    var username : String = ""
    var password : String = ""
}

class HostsModel : BindableObject {
    var hosts: [Host] {
        didSet { didChange.send() }
    }
    
    var didChange = PassthroughSubject<Void, Never>()
    
    init(hosts: [Host] = []) {
        self.hosts = hosts
    }
    
    class func sampleModel() -> HostsModel {
        let host = Host()
        host.alias = "some alias"
        host.hostname = "192.168.3.3"
        
        return HostsModel(hosts: [host])
    }
}
