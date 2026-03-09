//
//  JsonTokenizer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation

/// JSON syntax tokenizer
struct JsonTokenizer: SyntaxTokenizer {
	static let language = "json"

	func tokenize(_ input: String) -> [SyntaxToken] {
		var tokens: [SyntaxToken] = []
		var index = input.startIndex

		while index < input.endIndex {
			let char = input[index]

			// Whitespace
			if char.isWhitespace {
				let start = index
				while index < input.endIndex && input[index].isWhitespace {
					index = input.index(after: index)
				}
				tokens.append(SyntaxToken(String(input[start..<index]), .plain))
				continue
			}

			// String (key or value)
			if char == "\"" {
				let stringToken = parseString(input: input, from: &index)

				// Look ahead to see if this is a key (followed by colon)
				var lookAhead = index
				while lookAhead < input.endIndex && input[lookAhead].isWhitespace {
					lookAhead = input.index(after: lookAhead)
				}

				if lookAhead < input.endIndex && input[lookAhead] == ":" {
					tokens.append(SyntaxToken(stringToken, .key))
				} else {
					tokens.append(SyntaxToken(stringToken, .string))
				}
				continue
			}

			// Numbers
			if char == "-" || char.isNumber {
				let start = index
				if char == "-" {
					index = input.index(after: index)
				}
				while index < input.endIndex && isNumberChar(input[index]) {
					let current = input[index]
					if (current == "+" || current == "-") && index > start {
						let prev = input[input.index(before: index)]
						if prev != "e" && prev != "E" {
							break
						}
					}
					index = input.index(after: index)
				}
				tokens.append(SyntaxToken(String(input[start..<index]), .number))
				continue
			}

			// Boolean: true
			if char == "t" && input[index...].hasPrefix("true") {
				tokens.append(SyntaxToken("true", .boolean))
				index = input.index(index, offsetBy: 4)
				continue
			}

			// Boolean: false
			if char == "f" && input[index...].hasPrefix("false") {
				tokens.append(SyntaxToken("false", .boolean))
				index = input.index(index, offsetBy: 5)
				continue
			}

			// Null
			if char == "n" && input[index...].hasPrefix("null") {
				tokens.append(SyntaxToken("null", .null))
				index = input.index(index, offsetBy: 4)
				continue
			}

			// Punctuation
			if char == "{" || char == "}" || char == "[" || char == "]" || char == ":" || char == "," {
				tokens.append(SyntaxToken(String(char), .punctuation))
				index = input.index(after: index)
				continue
			}

			// Unknown character
			tokens.append(SyntaxToken(String(char), .error))
			index = input.index(after: index)
		}

		return tokens
	}

	private func isNumberChar(_ char: Character) -> Bool {
		char.isNumber || char == "." || char == "e" || char == "E" || char == "+" || char == "-"
	}

	private func parseString(input: String, from index: inout String.Index) -> String {
		var result = "\""
		index = input.index(after: index) // Skip opening quote

		while index < input.endIndex {
			let char = input[index]

			if char == "\\" && input.index(after: index) < input.endIndex {
				// Escape sequence
				result.append(char)
				index = input.index(after: index)
				result.append(input[index])
				index = input.index(after: index)
				continue
			}

			if char == "\"" {
				result.append(char)
				index = input.index(after: index)
				break
			}

			result.append(char)
			index = input.index(after: index)
		}

		return result
	}
}
