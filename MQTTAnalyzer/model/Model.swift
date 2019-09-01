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

class MessagesByTopic : Identifiable, ObservableObject {
    let topic: Topic
    
    @Published var read: Bool = true
    @Published var messages: [Message]
    @Published var timeSeries = Multimap<DiagramPath, TimeSeriesValue>()
    @Published var timeSeriesModels = [DiagramPath : MTimeSeriesModel]()

    var willChange = PassthroughSubject<Void, Never>()
    
    init(topic: Topic, messages: [Message]) {
        self.topic = topic
        self.messages = messages
    }

    func delete(at offsets: IndexSet) {
        // TODO how to remove all?
        messages.remove(at: offsets.first!)
    }

    func newMessage(_ message : Message) {
        read = false
        
        if (message.isJson()) {
            let jsonData = message.jsonData!
            if (jsonData.count > 0) {
                traverseJson(node: message.jsonData![0], path: "", dateFormatted: message.dateString)
            }
        }
        
        messages.insert(message, at: 0)
    }
    
    func traverseJson(node: Dictionary<String, Any>, path: String, dateFormatted: String) {
        print(node)
        
        node.forEach {
            let child = $0.value
            if (child is Dictionary<String, Any>) {
                let nextPath = path + $0.key
                traverseJson(node: child as! Dictionary<String, Any>, path: nextPath + ".", dateFormatted: dateFormatted)
            }
        }

        node.filter { $0.value is NSNumber }
            .forEach {
                let path = DiagramPath(path + $0.key)
                let value : NSNumber = $0.value as! NSNumber
                
                self.timeSeries.put(key: path, value: TimeSeriesValue(value: value, at: Date(), dateFormatted: dateFormatted))
                
                let val = MTimeSeriesValue(value: value, timestamp: Date())
                if let existingValues = self.timeSeriesModels[path] {
                    existingValues.values.append(val)
                    self.timeSeriesModels[path] = existingValues
                } else {
                    let model = MTimeSeriesModel()
                    model.values.append(val)
                    self.timeSeriesModels[path] = model
                }
            }
    }
    
    func markRead() {
        read = true
    }
    
    func getFirst() -> String {
        return messages.isEmpty ? "<undef>" : messages[0].data
    }
    
    func getDiagrams() -> [DiagramPath] {
        return Array(timeSeries._dict.keys)
    }
    
    func hasDiagrams() -> Bool {
        return timeSeries._dict.count > 0
    }
    
    func getTimeSeriesLastValue(_ path: DiagramPath) -> TimeSeriesValue? {
        let values = timeSeries._dict[path] ?? [TimeSeriesValue]()
        return values.last
    }
    
    func getTimeSeries(_ path: DiagramPath) -> [TimeSeriesValue] {
        return timeSeries._dict[path] ?? [TimeSeriesValue]()
    }
    
    func getTimeSeriesInt(_ path: DiagramPath) -> [Int] {
        return getTimeSeries(path).map { $0.num.intValue }
    }
    
    func getTimeSeriesId(_ path: DiagramPath) -> [TimeSeriesValue] {
        return getTimeSeries(path)
    }
    
    func getValuesLastHour(_ path: DiagramPath) -> [Int] {
        if let model = self.timeSeriesModels[path] {
            let values = model.getMeanValue(amount: 30, in: 30, to: Date())
                .map { $0.meanValue ?? 0 }
            
//            let minValue = values.filter {$0 != 0} .min() ?? 0
//            return values
//                .map { $0 == 0 ? 1 : $0 - minValue }
            
            return values
        } else {
            return [Int]()
        }
    }
}

class TimeSeriesValue : Hashable, Identifiable {
    let num : NSNumber
    let date : Date
    let dateString: String
    
    init(value num : NSNumber, at date: Date, dateFormatted: String) {
        self.num = num
        self.date = date
        self.dateString = dateFormatted
    }
    
    static func == (lhs: TimeSeriesValue, rhs: TimeSeriesValue) -> Bool {
        return lhs.num == rhs.num
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(num)
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
        let data = "[\(cleanEscapedNumbers(messageData))]".data(using: .utf8)!
        do {
            return try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>]
        } catch _ as NSError {
            return nil
        }
    }
    
    class func cleanEscapedNumbers(_ messageData: String) -> String {
        return messageData.replacingOccurrences(of: "[\"'](-?\\d+)[\"']",
        with: "$1",
        options: .regularExpression);
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

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

class MessageModel : ObservableObject {
    
    @Published var messagesByTopic: [String: MessagesByTopic]
    
    init(messagesByTopic: [String: MessagesByTopic] = [:]) {
        self.messagesByTopic = messagesByTopic
    }
    
    func sortedTopics() -> [MessagesByTopic] {
        return sortedTopicsByFilter(filter : nil)
    }
    
    func sortedTopicsByFilter(filter : String?) -> [MessagesByTopic] {
        var values = Array(messagesByTopic.values)
            
        values.sort {
            $0.topic.name < $1.topic.name
        }
        
//        let stuff = ["nate", "", nil, "loves", nil, "swift", ""]
//        let a = stuff.map { $0.nilIfEmpty }
//        print(a) // [Optional("nate"), nil, nil, Optional("loves"), nil, Optional("swift"), nil]

                
        return values.filter {
            let trimmed = filter?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return trimmed == nil || trimmed!.isBlank || $0.topic.name.localizedCaseInsensitiveContains(trimmed!)
            
//            let trimmed = filter?.trimmingCharacters(in: .whitespacesAndNewlines).nili
//
//            trimmed == nil || trimmed.isEmpty {
//                true
//                }
//                || $0.topic.name.localizedCaseInsensitiveContains(trimmed!)
        }
    }
    
    func readall() {
        messagesByTopic.values.forEach { $0.markRead() }
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

class Host : Identifiable, Hashable, ObservableObject {
    
    var alias : String = ""
    var hostname : String = ""
    var port : Int32 = 1883
    var topic : String = "#"
    
    var qos : Int = 0
    
    var auth : Bool = false
    var username : String = ""
    var password : String = ""
    
    var reconnectDelegate: (()->())?

    @Published var connected = false
    
    @Published var connecting = false
    
    func reconnect() {
        self.reconnectDelegate?()
    }
    
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

class HostsModel : ObservableObject {
    @Published var hosts: [Host]
    
    init(hosts: [Host] = []) {
        self.hosts = hosts
    }
    
    class func sampleModel() -> HostsModel {
        let host = Host()
//        host.alias = "pisvr"
//        host.hostname = "192.168.3.3"
        host.alias = "Mosquitto Test server"
        host.hostname = "test.mosquitto.org"
        host.topic = "de.wsv/#"
        //host.topic = "revspace/sensors/co2/#"
        //host.topic = "revspace/#"
        return HostsModel(hosts: [host])
    }
}
