//
//  MsgMetadata.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

struct Property: Identifiable {
	var id = UUID()
	let key: String
	let value: String
}

class MsgMetadata {
	let date: Date
	let localDate: String
	let qos: Int32
	let retain: Bool
	var responseTopic: String?
	var userProperty: [Property] = []

	init(qos: Int32, retain: Bool, date: Date = .now) {
		self.date = date
		self.localDate = DateFormatter.iso.string(from: self.date)
		self.qos = qos
		self.retain = retain
	}
}
