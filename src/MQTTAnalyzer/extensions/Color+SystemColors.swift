//
//  Color+Hex.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-05.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

#if os(iOS)
import UIKit

extension Color {
	static let systemGray6 = Color(UIColor.systemGray6)
	static let systemBackground = Color(UIColor.systemBackground)

	static func listBackground(_ colorScheme: ColorScheme) -> Color {
		return colorScheme == .dark ? Color.systemBackground : Color.systemGray6
	}

	static func listItemBackground(_ colorScheme: ColorScheme) -> Color {
		return colorScheme == .dark ? Color.systemGray6 : Color.systemBackground
	}
}

#elseif os(macOS)
import AppKit

extension Color {
	static let systemGray6 = Color(NSColor.controlBackgroundColor)
	static let systemBackground = Color(NSColor.windowBackgroundColor)

	static func listBackground(_ colorScheme: ColorScheme) -> Color {
		return colorScheme == .dark ? Color.systemBackground : Color.systemGray6
	}

	static func listItemBackground(_ colorScheme: ColorScheme) -> Color {
		return colorScheme == .dark ? Color.systemGray6 : Color.systemBackground
	}
}
#endif
