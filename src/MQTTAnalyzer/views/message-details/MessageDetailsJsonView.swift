//
//  MessageDetailsJsonView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import CodeEditor
import HighlightSwift

struct MessageDetailsJsonView: View {
	@Environment(\.colorScheme) var colorScheme
	@State var source: String
	@State private var language = CodeEditor.Language.json

	var body: some View {
		VStack {
			// CodeText(source).font(.footnote)
				// .frame(minHeight: 100, alignment: Alignment.leading)
			
			CodeEditor(source: $source,
					   language: language,
					   theme: colorScheme == .light ? CodeEditor.ThemeName.atelierSavannaLight : CodeEditor.ThemeName.atelierSavannaDark,
					   flags: CodeEditor.Flags.selectable)
				.frame(minHeight: 100, alignment: Alignment.leading)
		}
	}
}
