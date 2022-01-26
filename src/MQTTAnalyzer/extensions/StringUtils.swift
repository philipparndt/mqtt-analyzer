//
//  StringUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-05.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

let hexAlphabet = Array("0123456789abcdef".unicodeScalars)
extension DataProtocol {
	func hexStringEncoded() -> String {
		var i = 1
		return String(reduce(into: "".unicodeScalars) { result, value in
			result.append(hexAlphabet[Int(value / 0x10)])
			result.append(hexAlphabet[Int(value % 0x10)])
			if i % 2 == 0 {
				result.append(" ")
			}
			
			i += 1
		}).trimmingCharacters(in: [" "])
	}
	
	func hexBlockEncoded(len n: Int) -> String {
		var result: String = ""
		let array = Array(self)
		
		for i in stride(from: 0, to: self.count, by: n) {
			result += String(format: "%02X", i)
			result += ": "
			let x = Swift.min(i + n, self.count)
			let sub = array[i..<x]
			
			result += sub.hexStringEncoded()
			result += "\n"
		}
		
		return result
	}
}

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
	
	func pathUp(_ separator: String = "/") -> String {
		if let range = self.range(of: separator, options: .backwards ) {
			if range.lowerBound.utf16Offset(in: self) == 0 {
				return self
			}
			
			let index = self.index(range.lowerBound, offsetBy: -1)
			
			return String(self[...index])
		}
		return ""
	}
	
	var isBlank: Bool {
		return allSatisfy({ $0.isWhitespace })
	}
	
	// http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
	static func random(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map { _ in letters.randomElement()! })
	}
}
