//
//  MsgPayload.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class MsgPayload {
	let data: [UInt8]
	private var _jsonData: Any?
	private var jsonParsed = false
	private var _prettyJSON: String?

	var jsonData: Any? {
		if !jsonParsed {
			jsonParsed = true
			_jsonData = MsgPayload.toJson(str: dataStringCache)
		}
		return _jsonData
	}

	var isJSON: Bool {
		return jsonData != nil
	}
	var isBinary: Bool {
		return dataStringCache == nil
	}

	var contentType: String?

	private let dataStringCache: String?
	var dataString: String {
		return dataStringCache ?? "[\(data.count) bytes]"
	}

	/// Size of the payload in bytes
	var size: Int {
		return data.count
	}

	/// Formatted JSON string (cached)
	var prettyJSON: String {
		if let cached = _prettyJSON {
			return cached
		}
		guard let dataString = dataStringCache else { return "" }
		let formatted = JSONUtils.format(json: dataString)
		_prettyJSON = formatted
		return formatted
	}

	init(data: [UInt8]) {
		self.data = data
		self.dataStringCache = MsgPayload.toOptionalString(data: data)
	}
}

extension MsgPayload {
	class func toJson(str: String?) -> Any? {
		guard let str = str,
			  let data = str.data(using: .utf8),
			  let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
			return nil
		}
		return json
	}

	class func toOptionalString(data: [UInt8]) -> String? {
		return NSString(bytes: data, length: data.count, encoding: String.Encoding.utf8.rawValue) as String?
	}
}
