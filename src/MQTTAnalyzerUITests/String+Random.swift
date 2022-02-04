//
//  StringUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-05.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

extension String {
	// http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
	static func random(length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<length).map { _ in letters.randomElement()! })
	}
}
