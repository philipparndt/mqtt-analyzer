//
//  MessageDetailsJsonView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import CodeEditor

struct MessageDetailsJsonView: View {
	@Environment(\.colorScheme) var colorScheme
	@State var source: String
	@State private var language = CodeEditor.Language.json

	var body: some View {
		VStack {
			CodeEditor(source: $source,
					   language: language,
					   theme: colorScheme == .light
						   ? CodeEditor.ThemeName(rawValue: "github")
						   : CodeEditor.ThemeName(rawValue: "atom-one-dark"),
					   flags: CodeEditor.Flags.selectable)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		}
	}
}
