//
//  ButtonStyle.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ActionStyleTrailing: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.foregroundColor(.accentColor)
			.padding(EdgeInsets(top: 10, leading: 50, bottom: 10, trailing: 0))
	}
}

struct ActionStyleLeading: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.foregroundColor(.accentColor)
			.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 50))
	}
}
