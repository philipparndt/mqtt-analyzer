//
//  HostValidator.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

public class HostFormValidator {
	public class func validateHostname(name hostname: String) -> String? {
		let trimmed = hostname.trimmingCharacters(in: .whitespacesAndNewlines)

		if trimmed.contains("://") {
			return nil
		}

		return URL(string: trimmed) != nil ? trimmed : nil
	}

	public class func validateMaxMessagesOfSubFolders(value: String) -> Int32? {
		return validateInt(value: value, max: 1000)
	}

	public class func validatePort(port: String) -> Int32? {
		return validateInt(value: port, max: 65535)
	}

	public class func validateInt(value: String, max: Int) -> Int32? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard let intValue = Int(trimmed), intValue >= 0, intValue <= max else {
			return nil
		}
		return Int32(intValue)
	}

	private static let clientIDAllowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.")

	public class func validateClientID(id: String, random: Bool) -> String? {
		if random {
			return id
		}

		let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty,
			  trimmed.unicodeScalars.allSatisfy({ clientIDAllowedCharacters.contains($0) }) else {
			return nil
		}
		return trimmed
	}
}
