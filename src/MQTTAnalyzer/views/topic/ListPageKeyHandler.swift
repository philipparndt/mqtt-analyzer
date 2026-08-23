//
//  ListPageKeyHandler.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-08-23.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

#if os(macOS)
import SwiftUI
import AppKit

/// Takes the page keys away from the table before it acts on them.
///
/// A table scrolls a page without moving its selection, so handling the keys in
/// SwiftUI only corrects the result afterwards — the list visibly jumps away and
/// back. Consuming the event first prevents the scroll instead.
struct ListPageKeyHandler: NSViewRepresentable {
	/// Called with -1 for page up and 1 for page down.
	var onPage: (Int) -> Void

	func makeNSView(context: Context) -> NSView {
		let view = PageKeyView()
		view.onPage = onPage
		return view
	}

	func updateNSView(_ nsView: NSView, context: Context) {
		(nsView as? PageKeyView)?.onPage = onPage
	}

	final class PageKeyView: NSView {
		private static let pageUp: UInt16 = 116
		private static let pageDown: UInt16 = 121

		var onPage: ((Int) -> Void)?
		private var monitor: Any?

		override func viewDidMoveToWindow() {
			super.viewDidMoveToWindow()

			guard window != nil else {
				removeMonitor()
				return
			}

			guard monitor == nil else {
				return
			}

			monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
				self?.handle(event) ?? event
			}
		}

		deinit {
			removeMonitor()
		}

		private func removeMonitor() {
			if let monitor = monitor {
				NSEvent.removeMonitor(monitor)
			}
			monitor = nil
		}

		private func handle(_ event: NSEvent) -> NSEvent? {
			guard event.keyCode == Self.pageUp || event.keyCode == Self.pageDown else {
				return event
			}

			// Only while the list this view is drawn behind holds the keyboard
			guard let table = overlappingTable(), window?.firstResponder === table else {
				return event
			}

			onPage?(event.keyCode == Self.pageDown ? 1 : -1)
			return nil
		}

		/// The table drawn in the same area as this view.
		private func overlappingTable() -> NSTableView? {
			guard let window = window, let root = window.contentView else {
				return nil
			}

			let mine = convert(bounds, to: nil)
			return descendants(of: root)
				.compactMap { $0 as? NSTableView }
				.first { $0.convert($0.bounds, to: nil).intersects(mine) }
		}

		private func descendants(of view: NSView) -> [NSView] {
			view.subviews.flatMap { [$0] + descendants(of: $0) }
		}
	}
}
#endif
