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
    var read: Bool = true
    
    var messages: [Message] {
        didSet {
            didChange.send()
        }
    }
    
    var diagrams = Set<DiagramPath>()
    
    var didChange = PassthroughSubject<Void, Never>()

    init(topic: Topic, messages: [Message]) {
        self.topic = topic
        self.messages = messages
    }

    func delete(at offsets: IndexSet) {
        // TODO how to remove all?
        messages.remove(at: offsets.first!)
    }

    func newMessage(_ message : Message) {
        messages.insert(message, at: 0)
        read = false
        
        if (message.isJson()) {
            traverseJson(node: message.jsonData![0])
        }
    }
    
    func traverseJson(node: Dictionary<String, Any>) {
        print(node)
        
        node.forEach {
            let child = $0.value
            if (child is Dictionary<String, Any>) {
                traverseJson(node: child as! Dictionary<String, Any>)
            }
        }

        let numberKeys = node.filter { $0.value is NSNumber }
            .map { $0.key }
        
        numberKeys.map { DiagramPath($0) }
            .forEach { self.diagrams.insert($0)}
    }
    
    func markRead() {
        read = true
        didChange.send()
    }
    
    func getFirst() -> String {
        return messages.isEmpty ? "<undef>" : messages[0].data
    }
    
    func getDiagrams() -> [DiagramPath] {
        return Array(diagrams)
    }
}

class DiagramPath : Hashable, Identifiable {
    let path : String
    
    init(_ path : String) {
        self.path = path
    }
    
    static func == (lhs: DiagramPath, rhs: DiagramPath) -> Bool {
        return lhs.path == rhs.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
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

    init(_ name: String) {
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

    var messagesByTopic: [String: MessagesByTopic] {
        didSet { didChange.send() }
    }
    
    var didChange = PassthroughSubject<Void, Never>()
    
    init(messagesByTopic: [String: MessagesByTopic] = [:]) {
        self.messagesByTopic = messagesByTopic
    }
    
    func sortedTopics() -> [MessagesByTopic] {
        var values = Array(messagesByTopic.values)
            
        values.sort {
            $0.topic.name < $1.topic.name
        }
        
        return values
    }
    
    func readall() {
        messagesByTopic.values.forEach { $0.markRead() }
        
        didChange.send()
    }
    
    func countMessages() -> Int {
        return messagesByTopic.values.map { $0.messages.count }.reduce(0, +)
    }
    
    func delete(at offsets: IndexSet) {
        // TODO how to remove all?
        // messagesByTopic.remove(at: offsets.first!)
    }
    
    func append(topic: String, message: Message) {
//        let newGroup = MessagesByTopic(topic: Topic(topic), messages:[])
        //        messagesByTopic[topic, default: newGroup].debugAddMessage()
        
        var msgbt = messagesByTopic[topic]
        
        if (msgbt == nil) {
            msgbt = MessagesByTopic(topic: Topic(topic), messages:[])
            messagesByTopic[topic] = msgbt
        }
        
        msgbt!.newMessage(message)
        
        didChange.send()
    }
    
    class func sampleModel() -> MessageModel {
//        let vl = Topic("haus/ug/heizung/solar_vl")
        let vl = Topic("a")
        let rl = Topic("haus/ug/heizung/solar_rl")
        
        let result = MessageModel()

        var messagesByTopic : [String : MessagesByTopic] = [:]
        messagesByTopic[vl.name] = MessagesByTopic(topic: vl, messages: [
            Message(data: "{\"temperature\": 59.3125 }", date: Date()),
            Message(data: "{\"temperature\": 58.125 }", date: Date()),
            Message(data: "{\"temperature\": 56.125 }", date: Date()),
            Message(data: "{\"temperature\": 57.3125 }", date: Date()),
            Message(data: "{\"temperature\": 62.0 }", date: Date()),
            Message(data: "{\"temperature\": 58.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(timeIntervalSince1970: 1415637900))
            ])
        
        messagesByTopic[rl.name] = MessagesByTopic(topic: rl, messages: [
            Message(data: "{\"temperature\": 59.3125 }", date: Date())
            ])
        
        result.messagesByTopic = messagesByTopic;
        return result
    }
}

class Host : Identifiable, Hashable {
    var alias : String = ""
    var hostname : String = ""
    var port : UInt16 = 1883
    var topic : String = "#"
    
    var qos : Int = 0
    
    var auth : Bool = false
    var username : String = ""
    var password : String = ""
    
    static func == (lhs: Host, rhs: Host) -> Bool {
        return lhs.hostname == rhs.hostname
            && lhs.topic == rhs.topic
            && lhs.port == rhs.port
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hostname)
        hasher.combine(port)
        hasher.combine(topic)
    }
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
        host.alias = "pisvr"
        host.hostname = "192.168.3.3"
//        host.alias = "Mosquitto Test server"
//        host.hostname = "test.mosquitto.org"
        
        return HostsModel(hosts: [host])
    }
}
