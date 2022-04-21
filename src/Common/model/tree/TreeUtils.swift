//
//  TreeUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class TreeUtils {
	private class func removeAfterWildcard(_ subscription: String) -> String {
		if let idx = subscription.firstIndex(of: "#") {
			return String(subscription[...idx])
		}
		else {
			return subscription
		}
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
		.map { $0.replacingOccurrences(of: "[/#]+$", with: "", options: .regularExpression) }
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
