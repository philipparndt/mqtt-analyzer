//
//  MessageDetailsPlainTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsPlainTextView: View {
	let message: Message
	
	var body: some View {
		Text(message.data)
			.lineLimit(nil)
			.padding(10)
			.font(.system(.body, design: .monospaced))
	}
}
