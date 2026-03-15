//
//  MessageDetailsJsonView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#endif

struct MessageDetailsJsonView: View {
	let source: String
	let isJSON: Bool
	let payloadSize: Int

	/// Size thresholds for rendering strategy
	private enum SizeThreshold {
		static let syntaxHighlighting = 20_000     // 20KB - full syntax highlighting
		static let lazyRendering = 100_000         // 100KB - lazy rendering with line numbers
		// Above 100KB - preview only with export
	}

	init(payload: MsgPayload) {
		self.payloadSize = payload.size
		self.isJSON = true
		// Only pretty-print if small enough
		if payload.size <= SizeThreshold.syntaxHighlighting {
			self.source = payload.prettyJSON
		} else {
			self.source = payload.dataString
		}
	}

	init(source: String, isJSON: Bool) {
		self.source = source
		self.isJSON = isJSON
		self.payloadSize = source.utf8.count
	}

	var body: some View {
		if payloadSize <= SizeThreshold.syntaxHighlighting && isJSON {
			SyntaxHighlightedTextView(json: source)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		} else if payloadSize <= SizeThreshold.lazyRendering {
			LazyTextView(source: source, payloadSize: payloadSize)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		} else {
			LargeFileView(source: source, payloadSize: payloadSize)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		}
	}
}

// MARK: - Lazy Text View (for medium files up to 100KB)

private struct LazyTextView: View {
	let source: String
	let payloadSize: Int

	@State private var lines: [String]?
	@Environment(\.colorScheme) var colorScheme
	@State private var showCopiedFeedback = false

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			headerBanner

			if let lines = lines {
				ScrollView(.vertical) {
					LazyVStack(alignment: .leading, spacing: 0) {
						ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
							LineView(line: line, lineNumber: index + 1, totalLines: lines.count)
						}
					}
					.padding(12)
					.frame(maxWidth: .infinity, alignment: .leading)
				}
				.overlay(alignment: .topTrailing) {
					copyButton
						.padding(.top, 8)
						.padding(.trailing, 16)
				}
			} else {
				ProgressView("Loading...")
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
		.task {
			if lines == nil {
				// Split lines in background
				let result = source.components(separatedBy: "\n")
				await MainActor.run {
					lines = result
				}
			}
		}
	}

	private var headerBanner: some View {
		HStack(spacing: 6) {
			Image(systemName: "info.circle")
				.foregroundColor(.secondary)
			Text("Payload: \(formatBytes(payloadSize))")
				.font(.caption)
				.foregroundColor(.secondary)
			Spacer()
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 6)
		.background(Color.secondary.opacity(0.1))
	}

	private var copyButton: some View {
		Button {
			Pasteboard.copy(source)
			showCopiedFeedback = true
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				showCopiedFeedback = false
			}
		} label: {
			Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
				.foregroundColor(showCopiedFeedback ? .green : .secondary)
				#if os(iOS)
				.font(.system(size: 14))
				.frame(width: 44, height: 44)
				#else
				.frame(width: 28, height: 28)
				#endif
				.background(Color.listItemBackground(colorScheme))
				.cornerRadius(6)
		}
		.buttonStyle(.plain)
		.animation(.easeInOut(duration: 0.2), value: showCopiedFeedback)
	}
}

// MARK: - Line View

private struct LineView: View {
	let line: String
	let lineNumber: Int
	let totalLines: Int

	private var lineNumberWidth: Int {
		max(3, String(totalLines).count)
	}

	var body: some View {
		HStack(alignment: .top, spacing: 0) {
			Text(String(lineNumber))
				.font(.system(size: 11, design: .monospaced))
				.foregroundColor(.secondary.opacity(0.5))
				.frame(width: CGFloat(lineNumberWidth) * 7 + 8, alignment: .trailing)
				.padding(.trailing, 8)

			Text(line.isEmpty ? " " : line)
				.font(.system(.body, design: .monospaced))
				.textSelection(.enabled)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

// MARK: - Large File View (for files > 100KB - preview with export)

private struct LargeFileView: View {
	let source: String
	let payloadSize: Int

	@Environment(\.colorScheme) var colorScheme
	@State private var showCopiedFeedback = false
	@State private var showExporter = false
	@State private var exportDocument: TextFileDocument?
	@State private var preview: String?
	@State private var lineCount: Int?

	private let previewLines = 500

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			headerBanner

			if let preview = preview {
				ScrollView(.vertical) {
					Text(preview)
						.font(.system(.body, design: .monospaced))
						.textSelection(.enabled)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(12)
				}
			} else {
				ProgressView("Loading preview...")
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
		.fileExporter(
			isPresented: $showExporter,
			document: exportDocument,
			contentType: .json,
			defaultFilename: "mqtt-payload.json"
		) { _ in }
		.task {
			if preview == nil {
				// Extract preview and count lines in background
				let lines = source.components(separatedBy: "\n")
				let count = lines.count
				let previewText = lines.prefix(previewLines).joined(separator: "\n")
					+ (count > previewLines ? "\n\n... (\(count - previewLines) more lines)" : "")

				await MainActor.run {
					lineCount = count
					preview = previewText
				}
			}
		}
	}

	private var headerBanner: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 8) {
				Image(systemName: "doc.text")
					.foregroundColor(.orange)

				VStack(alignment: .leading, spacing: 2) {
					Text("Very large payload (\(formatBytes(payloadSize)))")
						.font(.caption)
						.fontWeight(.medium)
					if let lineCount = lineCount {
						Text("\(lineCount) lines - showing first \(min(previewLines, lineCount))")
							.font(.caption2)
							.foregroundColor(.secondary)
					} else {
						Text("Loading...")
							.font(.caption2)
							.foregroundColor(.secondary)
					}
				}

				Spacer()
			}

			HStack(spacing: 12) {
				Button {
					Pasteboard.copy(source)
					showCopiedFeedback = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
						showCopiedFeedback = false
					}
				} label: {
					Label(
						showCopiedFeedback ? "Copied!" : "Copy All",
						systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc"
					)
					.font(.caption)
				}
				.buttonStyle(.bordered)
				#if os(iOS)
				.controlSize(.small)
				#endif

				Button {
					exportDocument = TextFileDocument(text: source)
					showExporter = true
				} label: {
					Label("Export", systemImage: "square.and.arrow.up")
						.font(.caption)
				}
				.buttonStyle(.bordered)
				#if os(iOS)
				.controlSize(.small)
				#endif

				Spacer()
			}
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.background(Color.orange.opacity(0.1))
	}
}

// MARK: - Text File Document for Export

private struct TextFileDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.json, .plainText] }

	var text: String

	init(text: String) {
		self.text = text
	}

	init(configuration: ReadConfiguration) throws {
		if let data = configuration.file.regularFileContents,
		   let string = String(data: data, encoding: .utf8) {
			text = string
		} else {
			text = ""
		}
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let data = text.data(using: .utf8) ?? Data()
		return FileWrapper(regularFileWithContents: data)
	}
}

// MARK: - Helpers

private func formatBytes(_ bytes: Int) -> String {
	if bytes < 1024 {
		return "\(bytes) B"
	} else if bytes < 1024 * 1024 {
		return String(format: "%.1f KB", Double(bytes) / 1024)
	} else {
		return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
	}
}
