//
//  BrokerShareView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-25.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
struct BrokerShareSheet: UIViewControllerRepresentable {
	let fileURL: URL

	func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
