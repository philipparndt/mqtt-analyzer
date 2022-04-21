//
//  ReceivedMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

struct ReceivedMessage<M> {
	let message: M
	var responseTopic: String?
	var userProperty: [String: String]?
	var contentType: String?
}
