//
//  MessageModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-31.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine


class Message: Identifiable, JSONSerializable {
	var jsonData: [String: Any]?
	
    let data: String
	let date: Date
    let dateString: String
    let qos: Int32
	let retain: Bool
    
    init(data: String, date: Date, qos: Int32, retain: Bool) {
        self.data = data
        self.date = date
        self.qos = qos
        self.jsonData = Message.toJson(messageData: data)
		self.retain = retain
        
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
    
    class func toJson(messageData: String) -> [String: Any]? {
//        let data = "[\(cleanEscapedNumbers(messageData))]".data(using: .utf8)!
		let data = messageData.data(using: .utf8)!
        do {
			let data = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
			
			if let arrayOfArray = data as? [[String: Any]] {
				return arrayOfArray[0]
			}
			else {
				return data as? [String: Any]
			}
        } catch _ as NSError {
            return nil
        }
    }
    
    class func cleanEscapedNumbers(_ messageData: String) -> String {
        return messageData.replacingOccurrences(of: "[\"'](-?[1-9]+\\d*)[\"']",
        with: "$1",
        options: .regularExpression)
    }
}

class MessageModel: QuickFilterTextDebounce, ObservableObject {
    
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
    
    @Published var filter: String = "" {
        didSet {
            updateDisplayTopicsAsync()
        }
    }
    
    override func onChange(text: String) {
        if self.filter != text {
            self.filter = text
        }
    }
    
    @Published var displayTopics: [MessagesByTopic] = []
    
    var willChange = PassthroughSubject<Void, Never>()
    
    init(messagesByTopic: [String: MessagesByTopic] = [:]) {
        self.messagesByTopic = messagesByTopic
    }
    
    func setFilterImmediatelly(_ filter: String) {
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
        return sortedTopicsByFilter(filter: nil)
    }
    
    func sortedTopicsByFilter(filter: String?) -> [MessagesByTopic] {
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
        
        if msgbt == nil {
            msgbt = MessagesByTopic(topic: Topic(topic), messages: [])
            messagesByTopic[topic] = msgbt
        }
        
        msgbt!.newMessage(message)
        self.messageCount = countMessages()
    }
    
}
