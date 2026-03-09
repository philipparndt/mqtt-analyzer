//
//  SyntaxHighlightedTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// A view that displays syntax-highlighted text with native SwiftUI rendering
struct SyntaxHighlightedTextView: View {
	let source: String
	let tokenizer: any SyntaxTokenizer
	var showCopyButton: Bool = true
	var showLineNumbers: Bool = true

	@Environment(\.colorScheme) var colorScheme
	@State private var showCopiedFeedback = false

	private var lines: [String] {
		source.components(separatedBy: "\n")
	}

	var body: some View {
		#if os(iOS)
		iOSBody
		#else
		macOSBody
		#endif
	}

	#if os(iOS)
	private var iOSBody: some View {
		ScrollView(.vertical) {
			HStack(alignment: .top, spacing: 0) {
				if showLineNumbers {
					lineNumbersView
				}

				SelectableText(
					tokens: tokenizer.tokenize(source),
					theme: SyntaxTheme.forColorScheme(colorScheme)
				)
				.frame(maxWidth: .infinity, alignment: .topLeading)
				.padding(.top, 12)
				.padding(.bottom, 12)
				.padding(.trailing, 12)
				.padding(.leading, showLineNumbers ? 8 : 12)
			}
		}
		.overlay(alignment: .topTrailing) {
			if showCopyButton {
				copyButton
					.padding(.top, 8)
					.padding(.trailing, 20)
			}
		}
	}
	#endif

	#if os(macOS)
	private var macOSBody: some View {
		ScrollView(.vertical) {
			HStack(alignment: .top, spacing: 0) {
				if showLineNumbers {
					lineNumbersView
				}

				Text(attributedString)
					.font(.system(.body, design: .monospaced))
					.textSelection(.enabled)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity, alignment: .topLeading)
					.padding(.vertical, 12)
					.padding(.trailing, 12)
					.padding(.leading, showLineNumbers ? 8 : 12)
			}
		}
		.overlay(alignment: .topTrailing) {
			if showCopyButton {
				copyButton
					.padding(.top, 8)
					.padding(.trailing, 20)
			}
		}
	}
	#endif

	private var lineNumbersView: some View {
		#if os(iOS)
		SelectableLineNumbers(
			count: lines.count,
			theme: SyntaxTheme.forColorScheme(colorScheme)
		)
		#else
		Text(lineNumbersText)
			.font(.system(.body, design: .monospaced))
			.foregroundColor(.secondary.opacity(0.6))
			.multilineTextAlignment(.trailing)
			.fixedSize(horizontal: true, vertical: false)
			.padding(.vertical, 12)
			.padding(.horizontal, 8)
			.background(Color.secondary.opacity(0.05))
		#endif
	}

	private var lineNumbersText: String {
		(1...max(1, lines.count)).map { String($0) }.joined(separator: "\n")
	}

	private var copyButton: some View {
		Button(action: copySource) {
			Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
				.foregroundColor(showCopiedFeedback ? .green : .secondary)
				.frame(width: 16, height: 16)
		}
		.buttonStyle(.plain)
		.padding(6)
		.background(
			ZStack {
				Color.listItemBackground(colorScheme)
				if showCopiedFeedback {
					Color.green.opacity(0.15)
				}
			}
		)
		.cornerRadius(6)
		.animation(.easeInOut(duration: 0.2), value: showCopiedFeedback)
		#if os(macOS)
		.help("Copy")
		#endif
	}

	private func copySource() {
		Pasteboard.copy(source)
		showCopiedFeedback = true
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			showCopiedFeedback = false
		}
	}

	private var attributedString: AttributedString {
		let theme = SyntaxTheme.forColorScheme(colorScheme)
		let tokens = tokenizer.tokenize(source)

		var result = AttributedString()

		for token in tokens {
			var attributed = AttributedString(token.text)
			attributed.foregroundColor = theme.color(for: token.type)
			result.append(attributed)
		}

		return result
	}
}

// MARK: - Convenience initializers

extension SyntaxHighlightedTextView {
	/// Initialize with JSON source
	init(json source: String, showCopyButton: Bool = true, showLineNumbers: Bool = true) {
		self.source = source
		self.tokenizer = JsonTokenizer()
		self.showCopyButton = showCopyButton
		self.showLineNumbers = showLineNumbers
	}

	/// Initialize with language identifier
	init(source: String, language: String, showCopyButton: Bool = true, showLineNumbers: Bool = true) {
		self.source = source
		self.tokenizer = SyntaxTokenizerRegistry.tokenizer(for: language) ?? PlainTextTokenizer()
		self.showCopyButton = showCopyButton
		self.showLineNumbers = showLineNumbers
	}
}

// MARK: - Plain text fallback tokenizer

struct PlainTextTokenizer: SyntaxTokenizer {
	static let language = "plain"

	func tokenize(_ input: String) -> [SyntaxToken] {
		[SyntaxToken(input, .plain)]
	}
}

// MARK: - iOS Selectable Text

#if os(iOS)
private let iOSCodeFont = UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)

struct SelectableText: UIViewRepresentable {
	let tokens: [SyntaxToken]
	let theme: SyntaxTheme

	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		textView.isEditable = false
		textView.isSelectable = true
		textView.isScrollEnabled = false
		textView.backgroundColor = .clear
		textView.textContainerInset = .zero
		textView.textContainer.lineFragmentPadding = 0
		textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		return textView
	}

	func updateUIView(_ textView: UITextView, context: Context) {
		let result = NSMutableAttributedString()

		for token in tokens {
			let color = UIColor(theme.color(for: token.type))
			let attributes: [NSAttributedString.Key: Any] = [
				.font: iOSCodeFont,
				.foregroundColor: color
			]
			let attributed = NSAttributedString(string: token.text, attributes: attributes)
			result.append(attributed)
		}

		textView.attributedText = result
	}
}

struct SelectableLineNumbers: UIViewRepresentable {
	let count: Int
	let theme: SyntaxTheme

	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		textView.isEditable = false
		textView.isSelectable = false
		textView.isScrollEnabled = false
		textView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.3)
		textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
		textView.textContainer.lineFragmentPadding = 0
		textView.setContentHuggingPriority(.required, for: .horizontal)
		return textView
	}

	func updateUIView(_ textView: UITextView, context: Context) {
		let lineNumbers = (1...max(1, count)).map { String($0) }.joined(separator: "\n")

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .right

		let attributes: [NSAttributedString.Key: Any] = [
			.font: iOSCodeFont,
			.foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.6),
			.paragraphStyle: paragraphStyle
		]

		textView.attributedText = NSAttributedString(string: lineNumbers, attributes: attributes)
	}
}
#endif
