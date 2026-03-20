//
//  GlassCircleModifier.swift
//  MQTTAnalyzer
//

import SwiftUI

#if os(iOS)
struct GlassCircleModifier: ViewModifier {
	var color: Color = .accentColor

	func body(content: Content) -> some View {
		if #available(iOS 26.0, *) {
			content
				.foregroundColor(.white)
				.background(color)
				.clipShape(Circle())
				.glassEffect(.regular)
		} else {
			content
				.foregroundColor(.white)
				.background(color)
				.clipShape(Circle())
				.shadow(radius: 3, y: 2)
		}
	}
}
#endif
