//
//  MultilineTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

#if os(iOS)
import UIKit

struct MessageTextView: UIViewRepresentable {
	@Binding var text: String

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: Context) -> UITextView {
		let text = UITextView(frame: CGRect.zero)
		text.accessibilityIdentifier = "textbox"
		text.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
		text.isScrollEnabled = true
		text.isEditable = true
		text.isUserInteractionEnabled = true
		text.backgroundColor = UIColor(white: 0.0, alpha: 0.05)
		text.delegate = context.coordinator
		text.autocorrectionType = .no
		text.autocapitalizationType = .none
		text.smartDashesType = .no
		text.smartQuotesType = .no
		text.smartInsertDeleteType = .no
		return text
	}

	func updateUIView(_ uiView: UITextView, context: Context) {
		uiView.text = text
	}

	class Coordinator: NSObject, UITextViewDelegate {
		var parent: MessageTextView

		init(_ uiTextView: MessageTextView) {
			parent = uiTextView
		}

		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			return true
		}

		func textViewDidChange(_ textView: UITextView) {
			parent.text = textView.text
		}
	}
}

#elseif os(macOS)
import AppKit

struct MessageTextView: NSViewRepresentable {
	@Binding var text: String

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSTextView.scrollableTextView()
		guard let textView = scrollView.documentView as? NSTextView else {
			return scrollView
		}

		textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
		textView.isEditable = true
		textView.isSelectable = true
		textView.backgroundColor = NSColor(white: 0.0, alpha: 0.05)
		textView.delegate = context.coordinator
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.isAutomaticTextReplacementEnabled = false

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		guard let textView = nsView.documentView as? NSTextView else { return }
		if textView.string != text {
			textView.string = text
		}
	}

	class Coordinator: NSObject, NSTextViewDelegate {
		var parent: MessageTextView

		init(_ textView: MessageTextView) {
			parent = textView
		}

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			parent.text = textView.string
		}
	}
}
#endif
