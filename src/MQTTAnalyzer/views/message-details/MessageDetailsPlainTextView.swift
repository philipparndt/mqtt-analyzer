//
//  MessageDetailsPlainTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsPlainTextView: View {
	let message: MsgMessage
	
	var body: some View {
		VStack {
			Text(message.payload.dataString)
				.lineLimit(nil)
				.padding(10)
				.font(.system(.body, design: .monospaced))
			
			Spacer()
		}
	}
}
