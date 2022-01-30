//
//  MsgMetadata.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class MsgMetadata {
	let date: Date
	let localDate: String
	let qos: Int32
	let retain: Bool
	
	init(qos: Int32, retain: Bool) {
		self.date = Date.now
		self.localDate = DateFormatter.iso.string(from: self.date)
		self.qos = qos
		self.retain = retain
	}
}
