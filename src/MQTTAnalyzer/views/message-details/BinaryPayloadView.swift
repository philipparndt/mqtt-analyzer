//
//  BinaryPayloadView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2024-01-01.
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct BinaryPayloadView: View {
	let data: [UInt8]

	@State private var viewMode: ViewMode = .auto
	@Environment(\.colorScheme) var colorScheme

	private enum ViewMode: String, CaseIterable {
		case auto = "Auto"
		case hex = "Hex"
		case image = "Image"
	}

	private var detectedType: PayloadType {
		PayloadType.detect(from: data)
	}

	private var effectiveMode: ViewMode {
		if viewMode == .auto {
			return detectedType.isImage ? .image : .hex
		}
		return viewMode
	}

	var body: some View {
		VStack(spacing: 0) {
			// Mode picker for images (allow switching between image and hex)
			if detectedType.isImage {
				modePicker
			}

			// Content
			switch effectiveMode {
			case .image, .auto:
				if detectedType.isImage {
					ImagePayloadView(data: data, imageType: detectedType)
				} else {
					HexPayloadView(data: data)
				}
			case .hex:
				HexPayloadView(data: data)
			}
		}
	}

	private var modePicker: some View {
		HStack {
			Picker("View", selection: $viewMode) {
				ForEach([ViewMode.auto, ViewMode.image, ViewMode.hex], id: \.self) { mode in
					Text(mode.rawValue).tag(mode)
				}
			}
			.pickerStyle(.segmented)
			.frame(maxWidth: 250)

			Spacer()

			Text(detectedType.description)
				.font(.caption)
				.foregroundColor(.secondary)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(Color.secondary.opacity(0.1))
	}
}

// MARK: - Payload Type Detection

enum PayloadType {
	case png
	case jpeg
	case gif
	case webp
	case bmp
	case tiff
	case heic
	case unknown

	var isImage: Bool {
		switch self {
		case .unknown: return false
		default: return true
		}
	}

	var description: String {
		switch self {
		case .png: return "PNG Image"
		case .jpeg: return "JPEG Image"
		case .gif: return "GIF Image"
		case .webp: return "WebP Image"
		case .bmp: return "BMP Image"
		case .tiff: return "TIFF Image"
		case .heic: return "HEIC Image"
		case .unknown: return "Binary Data"
		}
	}

	static func detect(from data: [UInt8]) -> PayloadType {
		guard data.count >= 4 else { return .unknown }

		// PNG: 89 50 4E 47
		if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
			return .png
		}

		// JPEG: FF D8 FF
		if data.starts(with: [0xFF, 0xD8, 0xFF]) {
			return .jpeg
		}

		// GIF: 47 49 46 38 (GIF8)
		if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
			return .gif
		}

		// WebP: RIFF....WEBP
		if data.count >= 12 &&
		   data.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
		   data[8...11] == [0x57, 0x45, 0x42, 0x50] {
			return .webp
		}

		// BMP: 42 4D (BM)
		if data.starts(with: [0x42, 0x4D]) {
			return .bmp
		}

		// TIFF: 49 49 2A 00 (little endian) or 4D 4D 00 2A (big endian)
		if data.starts(with: [0x49, 0x49, 0x2A, 0x00]) ||
		   data.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
			return .tiff
		}

		// HEIC: ....ftyp followed by heic, heix, mif1, etc.
		if data.count >= 12 && data[4...7] == [0x66, 0x74, 0x79, 0x70] {
			return .heic
		}

		return .unknown
	}
}

// MARK: - Image Payload View

struct ImagePayloadView: View {
	let data: [UInt8]
	let imageType: PayloadType

	@State private var showCopiedFeedback = false
	@State private var showExporter = false
	@State private var exportDocument: ImageDocument?
	@Environment(\.colorScheme) var colorScheme

	#if os(iOS)
	private var image: UIImage? {
		UIImage(data: Data(data))
	}
	#else
	private var image: NSImage? {
		NSImage(data: Data(data))
	}
	#endif

	var body: some View {
		VStack(spacing: 0) {
			if let image = image {
				#if os(iOS)
				ZoomableImageView(image: image)
					.overlay(alignment: .topTrailing) {
						HStack(spacing: 8) {
							exportButton
							copyButton
						}
						.padding(.top, 8)
						.padding(.trailing, 16)
					}
				#else
				ZoomableImageViewMac(image: image)
					.overlay(alignment: .topTrailing) {
						HStack(spacing: 8) {
							exportButton
							copyButton
						}
						.padding(.top, 8)
						.padding(.trailing, 16)
					}
				#endif
			} else {
				ContentUnavailableView(
					"Cannot Display Image",
					systemImage: "photo.badge.exclamationmark",
					description: Text("The image data could not be decoded.")
				)
			}
		}
		.fileExporter(
			isPresented: $showExporter,
			document: exportDocument,
			contentType: imageType.utType,
			defaultFilename: "mqtt-image.\(imageType.fileExtension)"
		) { _ in }
	}

	private var copyButton: some View {
		Button {
			#if os(iOS)
			if let image = image {
				UIPasteboard.general.image = image
				showCopiedFeedback = true
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					showCopiedFeedback = false
				}
			}
			#else
			if let image = image {
				let pasteboard = NSPasteboard.general
				pasteboard.clearContents()
				pasteboard.writeObjects([image])
				showCopiedFeedback = true
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					showCopiedFeedback = false
				}
			}
			#endif
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

	private var exportButton: some View {
		Button {
			exportDocument = ImageDocument(data: Data(data))
			showExporter = true
		} label: {
			Image(systemName: "square.and.arrow.up")
				.foregroundColor(.secondary)
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
	}
}

extension PayloadType {
	var utType: UTType {
		switch self {
		case .png: return .png
		case .jpeg: return .jpeg
		case .gif: return .gif
		case .webp: return UTType(filenameExtension: "webp") ?? .data
		case .bmp: return .bmp
		case .tiff: return .tiff
		case .heic: return .heic
		case .unknown: return .data
		}
	}

	var fileExtension: String {
		switch self {
		case .png: return "png"
		case .jpeg: return "jpg"
		case .gif: return "gif"
		case .webp: return "webp"
		case .bmp: return "bmp"
		case .tiff: return "tiff"
		case .heic: return "heic"
		case .unknown: return "bin"
		}
	}
}

// MARK: - Image Document for Export

struct ImageDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.png, .jpeg, .gif, .bmp, .tiff, .heic, .data] }

	var data: Data

	init(data: Data) {
		self.data = data
	}

	init(configuration: ReadConfiguration) throws {
		data = configuration.file.regularFileContents ?? Data()
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		FileWrapper(regularFileWithContents: data)
	}
}

// MARK: - Zoomable Image View (iOS)

#if os(iOS)
struct ZoomableImageView: UIViewRepresentable {
	let image: UIImage

	func makeUIView(context: Context) -> UIScrollView {
		let scrollView = UIScrollView()
		scrollView.delegate = context.coordinator
		scrollView.minimumZoomScale = 0.1
		scrollView.maximumZoomScale = 5.0
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.bouncesZoom = true

		let imageView = UIImageView(image: image)
		imageView.contentMode = .scaleAspectFit
		imageView.isUserInteractionEnabled = true
		scrollView.addSubview(imageView)

		context.coordinator.imageView = imageView
		context.coordinator.scrollView = scrollView

		// Double tap to toggle between fit and 1:1
		let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		scrollView.addGestureRecognizer(doubleTap)

		return scrollView
	}

	func updateUIView(_ scrollView: UIScrollView, context: Context) {
		guard let imageView = context.coordinator.imageView else { return }

		imageView.image = image
		imageView.frame = CGRect(origin: .zero, size: image.size)
		scrollView.contentSize = image.size

		// Calculate scale to fit the image in the view
		DispatchQueue.main.async {
			let scrollViewSize = scrollView.bounds.size
			guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else { return }

			let widthScale = scrollViewSize.width / image.size.width
			let heightScale = scrollViewSize.height / image.size.height
			let minScale = min(widthScale, heightScale, 1.0) // Don't scale up small images

			scrollView.minimumZoomScale = min(minScale, 0.1)
			scrollView.zoomScale = minScale

			context.coordinator.centerImage()
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator: NSObject, UIScrollViewDelegate {
		weak var imageView: UIImageView?
		weak var scrollView: UIScrollView?

		func viewForZooming(in scrollView: UIScrollView) -> UIView? {
			imageView
		}

		func scrollViewDidZoom(_ scrollView: UIScrollView) {
			centerImage()
		}

		func centerImage() {
			guard let scrollView = scrollView, let imageView = imageView else { return }

			let scrollViewSize = scrollView.bounds.size
			let imageViewSize = imageView.frame.size

			let horizontalPadding = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
			let verticalPadding = max(0, (scrollViewSize.height - imageViewSize.height) / 2)

			scrollView.contentInset = UIEdgeInsets(
				top: verticalPadding,
				left: horizontalPadding,
				bottom: verticalPadding,
				right: horizontalPadding
			)
		}

		@objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
			guard let scrollView = scrollView else { return }

			if scrollView.zoomScale > scrollView.minimumZoomScale {
				// Zoom out to fit
				scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
			} else {
				// Zoom in to 1:1 or 2x, centered on tap point
				let location = gesture.location(in: scrollView)
				let zoomScale = min(1.0, scrollView.maximumZoomScale)
				let size = CGSize(
					width: scrollView.bounds.width / zoomScale,
					height: scrollView.bounds.height / zoomScale
				)
				let origin = CGPoint(
					x: location.x - size.width / 2,
					y: location.y - size.height / 2
				)
				scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
			}
		}
	}
}
#endif

// MARK: - Zoomable Image View (macOS)

#if os(macOS)
struct ZoomableImageViewMac: NSViewRepresentable {
	let image: NSImage

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSScrollView()
		scrollView.hasHorizontalScroller = true
		scrollView.hasVerticalScroller = true
		scrollView.allowsMagnification = true
		scrollView.minMagnification = 0.1
		scrollView.maxMagnification = 5.0
		scrollView.backgroundColor = .clear

		let imageView = NSImageView(image: image)
		imageView.imageScaling = .scaleProportionallyUpOrDown
		imageView.setFrameSize(image.size)

		scrollView.documentView = imageView
		context.coordinator.scrollView = scrollView

		return scrollView
	}

	func updateNSView(_ scrollView: NSScrollView, context: Context) {
		guard let imageView = scrollView.documentView as? NSImageView else { return }

		imageView.image = image
		imageView.setFrameSize(image.size)

		// Calculate scale to fit
		DispatchQueue.main.async {
			let scrollViewSize = scrollView.contentSize
			guard scrollViewSize.width > 0 && scrollViewSize.height > 0 else { return }

			let widthScale = scrollViewSize.width / image.size.width
			let heightScale = scrollViewSize.height / image.size.height
			let minScale = min(widthScale, heightScale, 1.0)

			scrollView.magnification = minScale
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator {
		weak var scrollView: NSScrollView?
	}
}
#endif

// MARK: - Hex Payload View

struct HexPayloadView: View {
	let data: [UInt8]

	@State private var showCopiedFeedback = false
	@State private var showExporter = false
	@State private var exportDocument: BinaryDocument?
	@Environment(\.colorScheme) var colorScheme

	#if os(iOS)
	private let bytesPerRow = 8
	#else
	private let bytesPerRow = 16
	#endif

	var body: some View {
		VStack(spacing: 0) {
			headerBanner

			ScrollView(.vertical) {
				LazyVStack(alignment: .leading, spacing: 0) {
					ForEach(0..<numberOfRows, id: \.self) { rowIndex in
						HexRowView(
							data: data,
							rowIndex: rowIndex,
							bytesPerRow: bytesPerRow,
							totalBytes: data.count
						)
					}
				}
				.padding(12)
			}
			.overlay(alignment: .topTrailing) {
				HStack(spacing: 8) {
					exportButton
					copyButton
				}
				.padding(.top, 8)
				.padding(.trailing, 16)
			}
		}
		.fileExporter(
			isPresented: $showExporter,
			document: exportDocument,
			contentType: .data,
			defaultFilename: "mqtt-payload.bin"
		) { _ in }
	}

	private var numberOfRows: Int {
		(data.count + bytesPerRow - 1) / bytesPerRow
	}

	private var headerBanner: some View {
		HStack(spacing: 6) {
			Image(systemName: "number")
				.foregroundColor(.secondary)
			Text("Binary data: \(formatBytes(data.count))")
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
			let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
			Pasteboard.copy(hexString)
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

	private var exportButton: some View {
		Button {
			exportDocument = BinaryDocument(data: Data(data))
			showExporter = true
		} label: {
			Image(systemName: "square.and.arrow.up")
				.foregroundColor(.secondary)
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
	}

	private func formatBytes(_ bytes: Int) -> String {
		if bytes < 1024 {
			return "\(bytes) bytes"
		} else if bytes < 1024 * 1024 {
			return String(format: "%.1f KB", Double(bytes) / 1024)
		} else {
			return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
		}
	}
}

// MARK: - Hex Row View

private struct HexRowView: View {
	let data: [UInt8]
	let rowIndex: Int
	let bytesPerRow: Int
	let totalBytes: Int

	@Environment(\.colorScheme) var colorScheme

	private var offset: Int {
		rowIndex * bytesPerRow
	}

	private var rowBytes: ArraySlice<UInt8> {
		let start = offset
		let end = min(start + bytesPerRow, totalBytes)
		return data[start..<end]
	}

	private var offsetWidth: Int {
		let maxOffset = totalBytes - 1
		if maxOffset < 0x10000 {
			return 4
		} else if maxOffset < 0x1000000 {
			return 6
		} else {
			return 8
		}
	}

	var body: some View {
		Text(buildAttributedRow())
			.font(.system(size: 11, design: .monospaced))
	}

	private func buildAttributedRow() -> AttributedString {
		var result = AttributedString()

		// Offset
		var offsetStr = AttributedString(String(format: "%0\(offsetWidth)X  ", offset))
		offsetStr.foregroundColor = .secondary
		result.append(offsetStr)

		// Hex bytes with pair grouping
		for i in 0..<bytesPerRow {
			if i < rowBytes.count {
				let byte = rowBytes[offset + i]
				var byteStr = AttributedString(String(format: "%02X", byte))
				byteStr.foregroundColor = byteColor(byte)
				result.append(byteStr)
			} else {
				result.append(AttributedString("  "))
			}

			// Spacing after byte
			if i < bytesPerRow - 1 {
				if i == bytesPerRow / 2 - 1 {
					// Extra space at halfway point
					result.append(AttributedString("  "))
				} else if i % 2 == 1 {
					// Space between pairs
					result.append(AttributedString(" "))
				}
				// No space within pairs (after even indices)
			}
		}

		// Separator
		var separator = AttributedString("  |")
		separator.foregroundColor = .secondary
		result.append(separator)

		// ASCII
		for i in 0..<rowBytes.count {
			let byte = rowBytes[offset + i]
			let char = isPrintable(byte) ? String(UnicodeScalar(byte)) : "."
			var charStr = AttributedString(char)
			charStr.foregroundColor = isPrintable(byte) ? .primary : .secondary
			result.append(charStr)
		}

		// Padding for incomplete rows
		if rowBytes.count < bytesPerRow {
			result.append(AttributedString(String(repeating: " ", count: bytesPerRow - rowBytes.count)))
		}

		var endPipe = AttributedString("|")
		endPipe.foregroundColor = .secondary
		result.append(endPipe)

		return result
	}

	private func byteColor(_ byte: UInt8) -> Color {
		if byte == 0x00 {
			return .secondary.opacity(0.5)
		} else if byte >= 0x20 && byte < 0x7F {
			return colorScheme == .dark ? .white : .black
		} else {
			return .blue
		}
	}

	private func isPrintable(_ byte: UInt8) -> Bool {
		byte >= 0x20 && byte < 0x7F
	}
}

// MARK: - Binary Document for Export

struct BinaryDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.data] }

	var data: Data

	init(data: Data) {
		self.data = data
	}

	init(configuration: ReadConfiguration) throws {
		data = configuration.file.regularFileContents ?? Data()
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		FileWrapper(regularFileWithContents: data)
	}
}
