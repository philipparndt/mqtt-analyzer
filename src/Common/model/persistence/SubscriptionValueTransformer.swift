//
//  SubscriptionValueTransformer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 14.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

@objc(Subscriptions)
public class Subscriptions: NSObject {
	var subscriptions: [TopicSubscription]
	
	init(_ subscritions: [TopicSubscription] = []) {
		self.subscriptions = subscritions
	}
}

@objc(SubscriptionValueTransformer)
public final class SubscriptionValueTransformer: ValueTransformer {
	public override class func transformedValueClass() -> AnyClass {
		return Subscriptions.self
	}
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		guard let subscriptions = value as? Subscriptions else {
			return nil
		}
		
		return SubscriptionValueTransformer.encode(subscriptions: subscriptions.subscriptions)
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? Data else { return nil }
		
		return Subscriptions(SubscriptionValueTransformer.decode(subscriptions: data))
	}
		
	static func encode(subscriptions: [TopicSubscription]) -> Data {
		do {
			return try JSONEncoder().encode(subscriptions)
		} catch {
			NSLog("Unexpected error encoding subscriptions: \(error).")
			return Data()
		}
	}
	
	static func decode(subscriptions: Data) -> [TopicSubscription] {
		do {
			if subscriptions.isEmpty {
				return []
			}
			
			return try JSONDecoder().decode([TopicSubscription].self, from: subscriptions)
		} catch {
			NSLog("Unexpected error decoding subscriptions: \(error).")
			NSLog("`\(String(data: subscriptions, encoding: .utf8)!)`")
			return [TopicSubscription(topic: "#", qos: 0)]
		}
	}
}
