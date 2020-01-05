//
//  StringUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-05.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

extension String {
	/*
	 Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
	 - Parameter length: Desired maximum lengths of a string
	 - Parameter trailing: A 'String' that will be appended after the truncation.

	 - Returns: 'String' object.
	*/
	func truncate(length: Int, trailing: String = "…") -> String {
		return (self.count > length) ? self.prefix(length) + trailing : self
	}
	
	func pathUp() -> String {
		if let range = self.range(of: "/", options: .backwards ) {
			let index = self.index(range.lowerBound, offsetBy: -1)
			
			return String(self[...index])
		}
		return ""
	}
	
	var isBlank: Bool {
		return allSatisfy({ $0.isWhitespace })
	}
}
