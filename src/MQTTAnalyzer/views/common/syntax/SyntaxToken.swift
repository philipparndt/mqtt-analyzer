//
//  SyntaxToken.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Token types for syntax highlighting
enum SyntaxTokenType {
	case plain
	case keyword
	case string
	case number
	case boolean
	case null
	case key
	case punctuation
	case comment
	case error
}

/// A token representing a piece of syntax-highlighted text
struct SyntaxToken {
	let text: String
	let type: SyntaxTokenType

	init(_ text: String, _ type: SyntaxTokenType) {
		self.text = text
		self.type = type
	}
}
