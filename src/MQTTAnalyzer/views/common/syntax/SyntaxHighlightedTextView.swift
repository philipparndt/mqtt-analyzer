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
			SelectableTextWithLineNumbers(
				source: source,
				tokens: tokenizer.tokenize(source),
				theme: SyntaxTheme.forColorScheme(colorScheme),
				showLineNumbers: showLineNumbers,
				tokenize: { tokenizer.tokenize($0) }
			)
			.frame(maxWidth: .infinity, alignment: .topLeading)
			.padding(12)
		}
		.overlay(alignment: .topTrailing) {
			if showCopyButton {
				copyButton
					.padding(.top, 4)
					.padding(.trailing, 16)
			}
		}
	}
	#endif

	#if os(macOS)
	private var macOSBody: some View {
		ScrollView(.vertical) {
			MacOSSelectableTextWithLineNumbers(
				source: source,
				tokenizer: tokenizer,
				theme: SyntaxTheme.forColorScheme(colorScheme),
				showLineNumbers: showLineNumbers
			)
			.padding(12)
		}
		.overlay(alignment: .topTrailing) {
			if showCopyButton {
				copyButton
					.padding(.top, 8)
					.padding(.trailing, 28)
			}
		}
	}
	#endif

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

// MARK: - iOS Selectable Text with Line Numbers

#if os(iOS)
private let iOSCodeFont = UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)

struct SelectableTextWithLineNumbers: View {
	let source: String
	let tokens: [SyntaxToken]
	let theme: SyntaxTheme
	let showLineNumbers: Bool
	var tokenize: ((String) -> [SyntaxToken])?

	@State private var calculatedHeight: CGFloat = 100

	var body: some View {
		GeometryReader { geometry in
			SelectableTextView(
				source: source,
				theme: theme,
				showLineNumbers: showLineNumbers,
				tokenize: tokenize,
				availableWidth: geometry.size.width,
				calculatedHeight: $calculatedHeight
			)
		}
		.frame(height: calculatedHeight)
	}
}

private struct SelectableTextView: UIViewRepresentable {
	let source: String
	let theme: SyntaxTheme
	let showLineNumbers: Bool
	var tokenize: ((String) -> [SyntaxToken])?
	let availableWidth: CGFloat
	@Binding var calculatedHeight: CGFloat

	private var lines: [String] {
		source.components(separatedBy: "\n")
	}

	private var lineNumberWidth: Int {
		max(2, String(lines.count).count)
	}

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
		let lineNumberColor = UIColor.secondaryLabel.withAlphaComponent(0.6)

		// Calculate the width of line number prefix in points for indentation
		let sampleLineNum = String(repeating: "0", count: lineNumberWidth) + "  "
		let lineNumPrefixWidth = (sampleLineNum as NSString).size(withAttributes: [.font: iOSCodeFont]).width

		// Build attributed string line by line
		for (index, line) in lines.enumerated() {
			let paragraphStyle = NSMutableParagraphStyle()
			if showLineNumbers {
				paragraphStyle.headIndent = lineNumPrefixWidth
			}

			// Add line number if enabled
			if showLineNumbers {
				let lineNum = String(index + 1).leftPadding(toLength: lineNumberWidth) + "  "
				let lineNumAttrs: [NSAttributedString.Key: Any] = [
					.font: iOSCodeFont,
					.foregroundColor: lineNumberColor,
					.paragraphStyle: paragraphStyle
				]
				result.append(NSAttributedString(string: lineNum, attributes: lineNumAttrs))
			}

			// Tokenize and add this line's content
			let lineTokens = tokenize?(line) ?? [SyntaxToken(line, .plain)]
			for token in lineTokens {
				let color = UIColor(theme.color(for: token.type))
				let attrs: [NSAttributedString.Key: Any] = [
					.font: iOSCodeFont,
					.foregroundColor: color,
					.paragraphStyle: paragraphStyle
				]
				result.append(NSAttributedString(string: token.text, attributes: attrs))
			}

			// Add newline except for last line
			if index < lines.count - 1 {
				result.append(NSAttributedString(string: "\n"))
			}
		}

		textView.attributedText = result

		// Calculate actual height needed for the content with wrapping
		DispatchQueue.main.async {
			let size = textView.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
			if size.height != calculatedHeight && size.height > 0 {
				calculatedHeight = size.height
			}
		}
	}
}
#endif

// MARK: - macOS Selectable Text with Line Numbers

#if os(macOS)
import AppKit

private let macOSCodeFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

struct MacOSSelectableTextWithLineNumbers: View {
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

	// Calculate approximate line number gutter width
	private var gutterWidth: CGFloat {
		let sampleText = String(repeating: "0", count: lineNumberWidth)
		let size = (sampleText as NSString).size(withAttributes: [.font: macOSCodeFont])
		return size.width + 16 // Add padding
	}

	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .top, spacing: 0) {
				if showLineNumbers {
					lineNumbersView
				}

				MacOSSelectableTextView(
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

	private var lineNumbersView: some View {
		MacOSLineNumbersView(
			lineHeights: lineHeights,
			lineNumberWidth: lineNumberWidth,
			selectedLines: selectedLines
		)
		.frame(width: gutterWidth)
		.contentShape(Rectangle())
		.clipped()
	}
}

private struct MacOSLineNumbersView: View {
	let lineHeights: [CGFloat]
	let lineNumberWidth: Int
	let selectedLines: Set<Int>
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(alignment: .trailing, spacing: 0) {
			ForEach(Array(lineHeights.enumerated()), id: \.offset) { index, height in
				let isSelected = selectedLines.contains(index)

				Text(String(index + 1).leftPadding(toLength: lineNumberWidth))
					.font(Font(macOSCodeFont))
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

private struct MacOSSelectableTextView: NSViewRepresentable {
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
		// Create custom text view with selection tracking
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

		// Set the text container width for proper wrapping
		let widthChanged = availableWidth > 0 && textView.textContainer?.containerSize.width != availableWidth
		if widthChanged {
			textView.textContainer?.containerSize = NSSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
			textView.frame.size.width = availableWidth
		}

		// Only update text if source changed to preserve selection
		let sourceChanged = context.coordinator.source != source
		if sourceChanged {
			context.coordinator.source = source

			let result = NSMutableAttributedString()

			for (index, line) in lines.enumerated() {
				let lineTokens = tokenizer.tokenize(line)
				for token in lineTokens {
					let color = NSColor(theme.color(for: token.type))
					let attributes: [NSAttributedString.Key: Any] = [
						.font: macOSCodeFont,
						.foregroundColor: color
					]
					result.append(NSAttributedString(string: token.text, attributes: attributes))
				}

				if index < lines.count - 1 {
					result.append(NSAttributedString(string: "\n", attributes: [.font: macOSCodeFont]))
				}
			}

			textView.textStorage?.setAttributedString(result)
		}

		// Force layout and calculate heights if needed
		if sourceChanged || widthChanged {
			DispatchQueue.main.async {
				self.calculateLineHeights(textView: textView)
			}
		}
	}

	private func calculateLineHeights(textView: NSTextView) {
		guard let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer,
			  let textStorage = textView.textStorage else { return }

		// Force complete layout
		layoutManager.ensureLayout(for: textContainer)

		var heights: [CGFloat] = []
		var charIndex = 0
		let defaultLineHeight = macOSCodeFont.ascender - macOSCodeFont.descender + macOSCodeFont.leading

		for (index, line) in lines.enumerated() {
			let lineLength = line.count
			let hasNewline = index < lines.count - 1

			// Get glyph range for this logical line (excluding newline for height calculation)
			let charRange = NSRange(location: charIndex, length: max(1, lineLength))
			let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)

			if glyphRange.length > 0 {
				// Get bounding rect for all glyphs in this line
				let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
				heights.append(ceil(max(boundingRect.height, defaultLineHeight)))
			} else {
				// Empty line
				heights.append(ceil(defaultLineHeight))
			}

			charIndex += lineLength + (hasNewline ? 1 : 0)
		}

		// Ensure we have at least one height entry
		if heights.isEmpty {
			heights = [defaultLineHeight]
		}

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

			let selectedRange = textView.selectedRange()

			// Find which lines are selected
			let lines = source.components(separatedBy: "\n")
			var selectedLineIndices = Set<Int>()

			if selectedRange.length > 0 {
				var charIndex = 0

				for (index, line) in lines.enumerated() {
					let lineLength = line.count
					let hasNewline = index < lines.count - 1
					let lineEnd = charIndex + lineLength + (hasNewline ? 1 : 0)

					// Check if this line overlaps with selection
					let selectionEnd = selectedRange.location + selectedRange.length
					if charIndex < selectionEnd && lineEnd > selectedRange.location {
						selectedLineIndices.insert(index)
					}

					charIndex = lineEnd
				}
			}

			// Dispatch async to avoid "Modifying state during view update"
			DispatchQueue.main.async { [weak self] in
				self?.onLinesSelected?(selectedLineIndices)
			}
		}
	}
}

private class SelectionTrackingTextView: NSTextView {
	var onSelectionChanged: (() -> Void)?

	override var selectedTextAttributes: [NSAttributedString.Key: Any] {
		get {
			return [
				.backgroundColor: NSColor.selectedTextBackgroundColor
			]
		}
		set { }
	}

	override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
		super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
		onSelectionChanged?()
		// Force redraw to clear any artifacts
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
