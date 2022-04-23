//
//  String+RegExp.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 08.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/42789953/swift-3-how-do-i-extract-captured-groups-in-regular-expressions
extension String {
	func groups(for regexPattern: String) -> [[String]] {
	do {
		let text = self
		let regex = try NSRegularExpression(pattern: regexPattern)
		let matches = regex.matches(in: text,
									range: NSRange(text.startIndex..., in: text))
		return matches.map { match in
			return (0..<match.numberOfRanges).map {
				let rangeBounds = match.range(at: $0)
				guard let range = Range(rangeBounds, in: text) else {
					return ""
				}
				return String(text[range])
			}
		}
	} catch let error {
		print("invalid regex: \(error.localizedDescription)")
		return []
	}
}
}
