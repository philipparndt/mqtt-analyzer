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
    
    @Published var read: Readstate = Readstate()
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
        read.markUnread()
        
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
    let qos : Int32
    
    let jsonData : [Dictionary<String, Any>]?
    
    init(data: String, date : Date, qos: Int32) {
        self.data = data
        self.date = date;
        self.qos = qos
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
        return data.data(using: .utf8)?.prettyPrintedJSONString ?? "{}"
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
        return messageData.replacingOccurrences(of: "[\"'](-?[1-9]+\\d*)[\"']",
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

class MessageModel : QuickFilterTextDebounce, ObservableObject {
    
    @Published var messagesByTopic: [String: MessagesByTopic] {
        willSet {
            willChange.send(Void())
        }
        
        didSet {
            updateDisplayTopics()
        }
    }

    @Published var messageCount: Int = 0 {
        willSet {
           willChange.send(Void())
       }
    }
    
    @Published var filter : String = "" {
        didSet {
            updateDisplayTopicsAsync()
        }
    }
    
    override func onChange(text: String) {
        if (self.filter != text) {
            self.filter = text
        }
    }
    
    @Published var displayTopics : [MessagesByTopic] = []
    
    var willChange = PassthroughSubject<Void, Never>()
    
    init(messagesByTopic: [String: MessagesByTopic] = [:]) {
        self.messagesByTopic = messagesByTopic
    }
    
    func setFilterImmediatelly(_ filter : String) {
        self.filter = filter
        self.filterText = filter
    }
    
    private func updateDisplayTopics() {
        self.messageCount = countMessages()
        self.displayTopics = self.sortedTopicsByFilter(filter: self.filter)
    }
    
    private func updateDisplayTopicsAsync() {
        // MARK: done this due to performance reasons
        // otherwise SwiftUI will trigger a repaint for each changed element
        self.displayTopics = []
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            self.updateDisplayTopics()
        }
    }
    
    func sortedTopics() -> [MessagesByTopic] {
        return sortedTopicsByFilter(filter : nil)
    }
    
    func sortedTopicsByFilter(filter : String?) -> [MessagesByTopic] {
        var values = Array(messagesByTopic.values)
            
        values.sort {
            $0.topic.name < $1.topic.name
        }
               
        return values.filter {
            let trimmed = filter?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return trimmed == nil || trimmed!.isBlank || $0.topic.name.localizedCaseInsensitiveContains(trimmed!)
        }
    }
    
    func readall() {
        messagesByTopic.values.forEach { $0.read.markRead() }
    }
    
    func clear() {
        messagesByTopic = [:]
    }
    
    func countMessages() -> Int {
        return messagesByTopic.values.map { $0.messages.count }.reduce(0, +)
    }
    
    func append(topic: String, message: Message) {
        willChange.send(Void())
        var msgbt = messagesByTopic[topic]
        
        if (msgbt == nil) {
            msgbt = MessagesByTopic(topic: Topic(topic), messages:[])
            messagesByTopic[topic] = msgbt
        }
        
        msgbt!.newMessage(message)
        self.messageCount = countMessages()
    }
    
}

class Host: Identifiable, Hashable, ObservableObject {
    
    var ID: String = NSUUID().uuidString
    
    var deleted = false
    
    var alias: String = ""
    var hostname: String = ""
    var port: Int32 = 1883
    var topic: String = "#"
    
    var qos: Int = 0
    
    var auth: Bool = false
    var username: String = ""
    var password: String = ""
    
    var connectionMessage: String?
    
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
    
    func delete(at offsets: IndexSet, persistence: HostsModelPersistence) {
        let original = hosts
        
        for idx in offsets {
            persistence.delete(original[idx])
        }
        
        var copy = hosts
        copy.remove(atOffsets: offsets)
        self.hosts = copy;
    }
    
    func delete(_ host : Host) {
        self.hosts = self.hosts.filter { $0 != host }
    }
}
