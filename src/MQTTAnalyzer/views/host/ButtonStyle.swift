//
//  ButtonStyle.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ActionStyleL25: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.foregroundColor(.accentColor)
			.padding(EdgeInsets(top: 10, leading: 25, bottom: 10, trailing: 0))
	}
}

struct ActionStyleL50: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.foregroundColor(.accentColor)
			.padding(EdgeInsets(top: 10, leading: 50, bottom: 10, trailing: 0))
	}
}

struct ActionStyleT50: ButtonStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.foregroundColor(.accentColor)
			.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 50))
	}
}
