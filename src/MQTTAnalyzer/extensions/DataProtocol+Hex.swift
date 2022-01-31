//
//  DataProtocol+Hex.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-31.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
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
			result += String(format: "%04X", i)
			result += ": "
			let x = Swift.min(i + n, self.count)
			let sub = array[i..<x]
			
			result += sub.hexStringEncoded()
			result += "\n"
		}
		
		return result
	}
}
