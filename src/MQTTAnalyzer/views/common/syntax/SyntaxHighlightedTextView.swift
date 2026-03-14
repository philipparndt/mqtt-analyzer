//
//  SyntaxHighlightedTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-09.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#else
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

// MARK: - Cross-platform font

private let codeFont: PlatformFont = {
	#if os(iOS)
	return PlatformFont.monospacedSystemFont(ofSize: PlatformFont.smallSystemFontSize, weight: .regular)
	#else
	return PlatformFont.monospacedSystemFont(ofSize: PlatformFont.systemFontSize, weight: .regular)
	#endif
}()

// MARK: - SyntaxHighlightedTextView

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
		ScrollView(.vertical) {
			SelectableTextWithLineNumbers(
				source: source,
				tokenizer: tokenizer,
				theme: SyntaxTheme.forColorScheme(colorScheme),
				showLineNumbers: showLineNumbers
			)
			.frame(maxWidth: .infinity, alignment: .topLeading)
			.padding(12)
		}
		.overlay(alignment: .topTrailing) {
			if showCopyButton {
				copyButton
					#if os(iOS)
					.padding(.top, 4)
					.padding(.trailing, 16)
					#else
					.padding(.top, 8)
					.padding(.trailing, 28)
					#endif
			}
		}
	}

	private var lineNumberWidth: Int {
		max(2, String(lines.count).count)
	}

	private var copyButton: some View {
		Button(action: copySource) {
			Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
				.foregroundColor(showCopiedFeedback ? .green : .secondary)
				#if os(iOS)
				.font(.system(size: 14))
				.frame(width: 44, height: 44)
				#else
				.frame(width: 28, height: 28)
				#endif
				.background(
					ZStack {
						Color.listItemBackground(colorScheme)
						if showCopiedFeedback {
							Color.green.opacity(0.15)
						}
					}
				)
				#if os(iOS)
				.cornerRadius(8)
				#else
				.cornerRadius(6)
				#endif
		}
		.buttonStyle(.plain)
		.contentShape(Rectangle())
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

// MARK: - Shared Line Numbers View

private struct LineNumbersView: View {
	let lineHeights: [CGFloat]
	let lineNumberWidth: Int
	let selectedLines: Set<Int>
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(alignment: .trailing, spacing: 0) {
			ForEach(Array(lineHeights.enumerated()), id: \.offset) { index, height in
				let isSelected = selectedLines.contains(index)

				Text(String(index + 1).leftPadding(toLength: lineNumberWidth))
					.font(Font(codeFont))
					.foregroundColor(isSelected ? selectedColor : .secondary.opacity(0.6))
					.frame(height: height, alignment: .topLeading)
					.frame(maxWidth: .infinity, alignment: .trailing)
					.padding(.trailing, 8)
			}
		}
		.drawingGroup()
	}

	private var selectedColor: Color {
		colorScheme == .dark ? .white : .accentColor
	}
}

// MARK: - Shared Selection Helper

private func calculateSelectedLines(source: String, selectedRange: NSRange) -> Set<Int> {
	let lines = source.components(separatedBy: "\n")
	var selectedLineIndices = Set<Int>()

	if selectedRange.length > 0 {
		var charIndex = 0

		for (index, line) in lines.enumerated() {
			let lineLength = line.count
			let hasNewline = index < lines.count - 1
			let lineEnd = charIndex + lineLength + (hasNewline ? 1 : 0)

			let selectionEnd = selectedRange.location + selectedRange.length
			if charIndex < selectionEnd && lineEnd > selectedRange.location {
				selectedLineIndices.insert(index)
			}

			charIndex = lineEnd
		}
	}

	return selectedLineIndices
}

// MARK: - Shared Line Height Calculator

private func calculateLineHeights(
	lines: [String],
	layoutManager: NSLayoutManager,
	textContainer: NSTextContainer,
	defaultLineHeight: CGFloat
) -> [CGFloat] {
	layoutManager.ensureLayout(for: textContainer)

	var heights: [CGFloat] = []
	var charIndex = 0

	for (index, line) in lines.enumerated() {
		let lineLength = line.count
		let hasNewline = index < lines.count - 1

		let charRange = NSRange(location: charIndex, length: max(1, lineLength))
		let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)

		if glyphRange.length > 0 {
			let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
			heights.append(ceil(max(boundingRect.height, defaultLineHeight)))
		} else {
			heights.append(ceil(defaultLineHeight))
		}

		charIndex += lineLength + (hasNewline ? 1 : 0)
	}

	if heights.isEmpty {
		heights = [defaultLineHeight]
	}

	return heights
}

// MARK: - Selectable Text with Line Numbers (Unified)

struct SelectableTextWithLineNumbers: View {
	let source: String
	let tokenizer: any SyntaxTokenizer
	let theme: SyntaxTheme
	let showLineNumbers: Bool

	@State private var lineHeights: [CGFloat] = []
	@State private var totalHeight: CGFloat = 100
	@State private var selectedLines: Set<Int> = []

	private var lines: [String] {
		source.components(separatedBy: "\n")
	}

	private var lineNumberWidth: Int {
		max(2, String(lines.count).count)
	}

	private var gutterWidth: CGFloat {
		let sampleText = String(repeating: "0", count: lineNumberWidth)
		let size = (sampleText as NSString).size(withAttributes: [.font: codeFont])
		return size.width + 16
	}

	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .top, spacing: 0) {
				if showLineNumbers {
					LineNumbersView(
						lineHeights: lineHeights,
						lineNumberWidth: lineNumberWidth,
						selectedLines: selectedLines
					)
					.frame(width: gutterWidth)
					.contentShape(Rectangle())
					.clipped()
				}

				PlatformSelectableTextView(
					source: source,
					tokenizer: tokenizer,
					theme: theme,
					lineHeights: $lineHeights,
					totalHeight: $totalHeight,
					selectedLines: $selectedLines,
					availableWidth: geometry.size.width - (showLineNumbers ? gutterWidth + 8 : 0)
				)
				.frame(maxWidth: .infinity, alignment: .topLeading)
				.padding(.leading, showLineNumbers ? 8 : 0)
			}
		}
		.frame(height: totalHeight)
	}
}

// MARK: - Platform-Specific Text View

#if os(iOS)

private struct PlatformSelectableTextView: UIViewRepresentable {
	let source: String
	let tokenizer: any SyntaxTokenizer
	let theme: SyntaxTheme
	@Binding var lineHeights: [CGFloat]
	@Binding var totalHeight: CGFloat
	@Binding var selectedLines: Set<Int>
	let availableWidth: CGFloat

	private var lines: [String] {
		source.components(separatedBy: "\n")
	}

	func makeUIView(context: Context) -> UITextView {
		let textContainer = NSTextContainer()
		textContainer.widthTracksTextView = true
		textContainer.lineFragmentPadding = 0

		let layoutManager = NSLayoutManager()
		layoutManager.addTextContainer(textContainer)

		let textStorage = NSTextStorage()
		textStorage.addLayoutManager(layoutManager)

		let textView = SelectionTrackingTextView(frame: .zero, textContainer: textContainer)
		textView.isEditable = false
		textView.isSelectable = true
		textView.isScrollEnabled = false
		textView.backgroundColor = .clear
		textView.textContainerInset = .zero
		textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

		let coordinator = context.coordinator
		textView.delegate = coordinator
		textView.onSelectionChanged = { [weak coordinator] in
			coordinator?.updateSelection()
		}
		coordinator.textView = textView
		coordinator.onLinesSelected = { selectedLineIndices in
			selectedLines = selectedLineIndices
		}

		return textView
	}

	func updateUIView(_ textView: UITextView, context: Context) {
		let widthChanged = availableWidth > 0 && textView.textContainer.size.width != availableWidth
		if widthChanged {
			textView.textContainer.size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
			textView.frame.size.width = availableWidth
		}

		let sourceChanged = context.coordinator.source != source
		if sourceChanged {
			context.coordinator.source = source
			textView.textStorage.setAttributedString(buildAttributedString())
		}

		if sourceChanged || widthChanged {
			DispatchQueue.main.async {
				self.updateHeights(textView: textView)
			}
		}
	}

	private func buildAttributedString() -> NSAttributedString {
		let result = NSMutableAttributedString()

		for (index, line) in lines.enumerated() {
			let lineTokens = tokenizer.tokenize(line)
			for token in lineTokens {
				let color = PlatformColor(theme.color(for: token.type))
				let attributes: [NSAttributedString.Key: Any] = [
					.font: codeFont,
					.foregroundColor: color
				]
				result.append(NSAttributedString(string: token.text, attributes: attributes))
			}

			if index < lines.count - 1 {
				result.append(NSAttributedString(string: "\n", attributes: [.font: codeFont]))
			}
		}

		return result
	}

	private func updateHeights(textView: UITextView) {
		let defaultLineHeight = codeFont.ascender - codeFont.descender + codeFont.leading
		let heights = calculateLineHeights(
			lines: lines,
			layoutManager: textView.layoutManager,
			textContainer: textView.textContainer,
			defaultLineHeight: defaultLineHeight
		)

		if heights != lineHeights {
			lineHeights = heights
		}

		let newTotalHeight = heights.reduce(0, +)
		if abs(newTotalHeight - totalHeight) > 1 && newTotalHeight > 0 {
			totalHeight = newTotalHeight
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator: NSObject, UITextViewDelegate {
		weak var textView: UITextView?
		var source: String = ""
		var onLinesSelected: ((Set<Int>) -> Void)?

		func updateSelection() {
			guard let textView = textView else { return }
			let selected = calculateSelectedLines(source: source, selectedRange: textView.selectedRange)
			DispatchQueue.main.async { [weak self] in
				self?.onLinesSelected?(selected)
			}
		}

		func textViewDidChangeSelection(_ textView: UITextView) {
			updateSelection()
		}
	}
}

private class SelectionTrackingTextView: UITextView {
	var onSelectionChanged: (() -> Void)?

	override var selectedTextRange: UITextRange? {
		didSet {
			onSelectionChanged?()
			setNeedsDisplay()
		}
	}
}

#else // macOS

private struct PlatformSelectableTextView: NSViewRepresentable {
	let source: String
	let tokenizer: any SyntaxTokenizer
	let theme: SyntaxTheme
	@Binding var lineHeights: [CGFloat]
	@Binding var totalHeight: CGFloat
	@Binding var selectedLines: Set<Int>
	let availableWidth: CGFloat

	private var lines: [String] {
		source.components(separatedBy: "\n")
	}

	func makeNSView(context: Context) -> NSScrollView {
		let textContainer = NSTextContainer()
		textContainer.widthTracksTextView = true
		textContainer.lineFragmentPadding = 0

		let layoutManager = NSLayoutManager()
		layoutManager.addTextContainer(textContainer)

		let textStorage = NSTextStorage()
		textStorage.addLayoutManager(layoutManager)

		let textView = SelectionTrackingTextView(frame: .zero, textContainer: textContainer)
		textView.isEditable = false
		textView.isSelectable = true
		textView.backgroundColor = .clear
		textView.drawsBackground = false
		textView.textContainerInset = .zero
		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = false
		textView.autoresizingMask = [.width]

		let coordinator = context.coordinator
		textView.delegate = coordinator
		textView.onSelectionChanged = { [weak coordinator] in
			coordinator?.updateSelection()
		}
		coordinator.textView = textView
		coordinator.onLinesSelected = { selectedLineIndices in
			selectedLines = selectedLineIndices
		}

		let scrollView = NSScrollView()
		scrollView.hasVerticalScroller = false
		scrollView.hasHorizontalScroller = false
		scrollView.borderType = .noBorder
		scrollView.drawsBackground = false
		scrollView.documentView = textView

		return scrollView
	}

	func updateNSView(_ scrollView: NSScrollView, context: Context) {
		guard let textView = scrollView.documentView as? NSTextView else { return }

		let widthChanged = availableWidth > 0 && textView.textContainer?.containerSize.width != availableWidth
		if widthChanged {
			textView.textContainer?.containerSize = NSSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
			textView.frame.size.width = availableWidth
		}

		let sourceChanged = context.coordinator.source != source
		if sourceChanged {
			context.coordinator.source = source
			textView.textStorage?.setAttributedString(buildAttributedString())
		}

		if sourceChanged || widthChanged {
			DispatchQueue.main.async {
				self.updateHeights(textView: textView)
			}
		}
	}

	private func buildAttributedString() -> NSAttributedString {
		let result = NSMutableAttributedString()

		for (index, line) in lines.enumerated() {
			let lineTokens = tokenizer.tokenize(line)
			for token in lineTokens {
				let color = PlatformColor(theme.color(for: token.type))
				let attributes: [NSAttributedString.Key: Any] = [
					.font: codeFont,
					.foregroundColor: color
				]
				result.append(NSAttributedString(string: token.text, attributes: attributes))
			}

			if index < lines.count - 1 {
				result.append(NSAttributedString(string: "\n", attributes: [.font: codeFont]))
			}
		}

		return result
	}

	private func updateHeights(textView: NSTextView) {
		guard let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer else { return }

		let defaultLineHeight = codeFont.ascender - codeFont.descender + codeFont.leading
		let heights = calculateLineHeights(
			lines: lines,
			layoutManager: layoutManager,
			textContainer: textContainer,
			defaultLineHeight: defaultLineHeight
		)

		if heights != lineHeights {
			lineHeights = heights
		}

		let newTotalHeight = heights.reduce(0, +)
		if abs(newTotalHeight - totalHeight) > 1 && newTotalHeight > 0 {
			totalHeight = newTotalHeight
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator: NSObject, NSTextViewDelegate {
		weak var textView: NSTextView?
		var source: String = ""
		var onLinesSelected: ((Set<Int>) -> Void)?

		func updateSelection() {
			guard let textView = textView else { return }
			let selected = calculateSelectedLines(source: source, selectedRange: textView.selectedRange())
			DispatchQueue.main.async { [weak self] in
				self?.onLinesSelected?(selected)
			}
		}
	}
}

private class SelectionTrackingTextView: NSTextView {
	var onSelectionChanged: (() -> Void)?

	override var selectedTextAttributes: [NSAttributedString.Key: Any] {
		get {
			return [.backgroundColor: NSColor.selectedTextBackgroundColor]
		}
		set { }
	}

	override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
		super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
		onSelectionChanged?()
		needsDisplay = true
	}
}

#endif

// MARK: - String Helpers

private extension String {
	func leftPadding(toLength length: Int) -> String {
		if count >= length { return self }
		return String(repeating: " ", count: length - count) + self
	}
}
