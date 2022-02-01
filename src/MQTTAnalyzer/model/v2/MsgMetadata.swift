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
		if #available(macCatalyst 15, *) {
			self.date = Date.now
		} else {
			// Fallback on earlier versions
			self.date = Date()
		}
		self.localDate = DateFormatter.iso.string(from: self.date)
		self.qos = qos
		self.retain = retain
	}
}
