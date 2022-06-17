//
//  ModelTestExtensions.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
@testable import MQTTAnalyzer

extension MsgPayload {
	class func from(text: String) -> MsgPayload {
		return MsgPayload(data: Array(text.utf8))
	}
}

extension MsgMetadata {
	class func stub() -> MsgMetadata {
		return MsgMetadata(qos: 0, retain: true)
	}
	
	class func stub(date: Date) -> MsgMetadata {
		return MsgMetadata(qos: 0, retain: true, date: date)
	}
}
