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
		let label = UITextView(frame: CGRect.zero)
		label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
		label.isScrollEnabled = true
		label.isEditable = true
		label.isUserInteractionEnabled = true
		label.backgroundColor = UIColor(white: 0.0, alpha: 0.05)
		label.delegate = context.coordinator
		label.autocorrectionType = .no
		label.autocapitalizationType = .none
		label.smartDashesType = .no
		label.smartQuotesType = .no
		label.smartInsertDeleteType = .no
		return label
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
