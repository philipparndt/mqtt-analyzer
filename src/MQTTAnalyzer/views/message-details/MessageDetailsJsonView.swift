//
//  MessageDetailsJsonView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsJsonView: View {
	let source: String

	var body: some View {
		SyntaxHighlightedTextView(json: source)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
	}
}
