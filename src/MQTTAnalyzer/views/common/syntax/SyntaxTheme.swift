//
//  SyntaxTheme.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// Color theme for syntax highlighting
struct SyntaxTheme {
	let plain: Color
	let keyword: Color
	let string: Color
	let number: Color
	let boolean: Color
	let null: Color
	let key: Color
	let punctuation: Color
	let comment: Color
	let error: Color

	func color(for tokenType: SyntaxTokenType) -> Color {
		switch tokenType {
		case .plain: return plain
		case .keyword: return keyword
		case .string: return string
		case .number: return number
		case .boolean: return boolean
		case .null: return null
		case .key: return key
		case .punctuation: return punctuation
		case .comment: return comment
		case .error: return error
		}
	}
}

extension SyntaxTheme {
	/// Light theme inspired by Xcode
	static let light = SyntaxTheme(
		plain: .primary,
		keyword: Color(red: 0.67, green: 0.05, blue: 0.57),     // #aa0d91 - purple
		string: Color(red: 0.77, green: 0.10, blue: 0.09),      // #c41a16 - red
		number: Color(red: 0.11, green: 0.00, blue: 0.81),      // #1c00cf - blue
		boolean: Color(red: 0.67, green: 0.05, blue: 0.57),     // #aa0d91 - purple
		null: Color(red: 0.67, green: 0.05, blue: 0.57),        // #aa0d91 - purple
		key: Color(red: 0.36, green: 0.15, blue: 0.60),         // #5c2699 - dark purple
		punctuation: .primary,
		comment: Color(red: 0.00, green: 0.45, blue: 0.00),     // #007400 - green
		error: .red
	)

	/// Dark theme inspired by Xcode
	static let dark = SyntaxTheme(
		plain: .primary,
		keyword: Color(red: 0.99, green: 0.37, blue: 0.64),     // #FC5FA3 - pink
		string: Color(red: 0.99, green: 0.42, blue: 0.36),      // #FC6A5D - coral
		number: Color(red: 0.82, green: 0.66, blue: 1.00),      // #D0A8FF - light purple
		boolean: Color(red: 0.99, green: 0.37, blue: 0.64),     // #FC5FA3 - pink
		null: Color(red: 0.99, green: 0.37, blue: 0.64),        // #FC5FA3 - pink
		key: Color(red: 0.25, green: 0.63, blue: 0.75),         // #41A1C0 - teal
		punctuation: .primary,
		comment: Color(red: 0.42, green: 0.47, blue: 0.53),     // #6C7986 - gray
		error: .red
	)

	/// Returns appropriate theme for color scheme
	static func forColorScheme(_ colorScheme: ColorScheme) -> SyntaxTheme {
		colorScheme == .dark ? .dark : .light
	}
}
