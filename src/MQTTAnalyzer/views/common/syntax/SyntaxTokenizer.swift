//
//  SyntaxTokenizer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// Protocol for language-specific tokenizers
protocol SyntaxTokenizer {
	/// The language identifier
	static var language: String { get }

	/// Required initializer
	init()

	/// Tokenize the input string into syntax tokens
	func tokenize(_ input: String) -> [SyntaxToken]
}

/// Registry for available tokenizers
enum SyntaxTokenizerRegistry {
	private static var tokenizers: [String: any SyntaxTokenizer.Type] = [
		JsonTokenizer.language: JsonTokenizer.self
	]

	static func tokenizer(for language: String) -> (any SyntaxTokenizer)? {
		tokenizers[language]?.init()
	}

	static func register(_ tokenizer: any SyntaxTokenizer.Type) {
		tokenizers[tokenizer.language] = tokenizer
	}
}
