//
//  MsgPayload.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftyJSON

class MsgPayload {
	let data: [UInt8]
	var jsonData: JSON?
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

	init(data: [UInt8]) {
		self.data = data
		self.dataStringCache = MsgPayload.toOptionalString(data: data)
		self.jsonData = MsgPayload.toJson(str: dataStringCache)
	}
}

extension MsgPayload {
	var prettyJSON: String {
		return dataStringCache != nil ? JSONUtils.format(json: dataStringCache!) : ""
	}
}

extension MsgPayload {
	class func toJson(str: String?) -> JSON? {
		if str == nil {
			return nil
		}
		
		let json = JSON.init(parseJSON: str!)
		if json.isEmpty {
			return nil
		}
		else {
			return json
		}
	}
	
	class func toOptionalString(data: [UInt8]) -> String? {
		return NSString(bytes: data, length: data.count, encoding: String.Encoding.utf8.rawValue) as String?
	}
}
