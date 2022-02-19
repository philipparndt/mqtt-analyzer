//
//  MultilineTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageTextView: UIViewRepresentable {
	@Binding var text: String

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: Context) -> UITextView {
		let text = UITextView(frame: CGRect.zero)
		text.accessibilityLabel = "textbox"
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
