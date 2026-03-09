//
//  TreeUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class TreeUtils {
	/// Check if a topic matches an MQTT subscription pattern with wildcards
	/// - Parameters:
	///   - topic: The actual topic (e.g., "home/sensor/temperature")
	///   - subscription: The subscription pattern (e.g., "home/+/temperature" or "home/#")
	/// - Returns: true if the topic matches the subscription pattern
	class func topicMatchesSubscription(topic: String, subscription: String) -> Bool {
		// Exact match
		if topic == subscription {
			return true
		}

		let topicParts = topic.split(separator: "/", omittingEmptySubsequences: false).map { String($0) }
		let subParts = subscription.split(separator: "/", omittingEmptySubsequences: false).map { String($0) }

		var topicIndex = 0
		var subIndex = 0

		while subIndex < subParts.count {
			let subPart = subParts[subIndex]

			if subPart == "#" {
				// # matches everything from here to the end (must be last)
				return true
			} else if subPart == "+" {
				// + matches exactly one level
				if topicIndex >= topicParts.count {
					return false
				}
				topicIndex += 1
				subIndex += 1
			} else {
				// Literal match required
				if topicIndex >= topicParts.count || topicParts[topicIndex] != subPart {
					return false
				}
				topicIndex += 1
				subIndex += 1
			}
		}

		// Both must be exhausted for a match (unless # was used)
		return topicIndex == topicParts.count
	}

	private class func remove(after wildcard: String.Element, _ subscription: String) -> String {
		if let idx = subscription.firstIndex(of: wildcard) {
			return String(subscription[...idx])
		}
		else {
			return subscription
		}
	}
	
	private class func removeAfterWildcard(_ subscription: String) -> String {
		return remove(after: "+", remove(after: "#", subscription))
	}
		
	private class func commonPath(_ left: [String], _ right: [String]) -> [String] {
		var result: [String] = []
		for i in 0 ..< min(left.count, right.count) {
			if left[i] != right[i] {
				return result
			}
			
			result.append(left[i])
		}
		
		return result
	}
	
	class func commomPrefix(subscriptions: [String]) -> String {
		return subscriptions.map { TreeUtils.removeAfterWildcard($0) }
		.map { $0.replacingOccurrences(of: "[/#+]+$", with: "", options: .regularExpression) }
		.map { $0.split(separator: "/").map { String($0)} }
		.reduce(nil as [String]?, {
			if $0 == nil {
				return $1
			}
			
			return commonPath($0!, $1)
		})
		.map { $0.joined(separator: "/") } ?? ""
	}
}
