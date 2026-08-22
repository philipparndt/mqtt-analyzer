//
//  ListFocusRestorer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-08-22.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

#if os(macOS)
import AppKit

/// Restores the first responder a click on a list used to give it.
///
/// Built against the macOS 26/27 SDK, clicking a row of a SwiftUI List no longer
/// makes the list the first responder: the selection stays drawn in its inactive
/// grey, and the arrow keys keep going to the search field of the column. The same
/// source built against the previous SDK behaves correctly, so this compensates for
/// the framework rather than for anything in the view code.
enum ListFocusRestorer {
	private static var monitor: Any?

	static func install() {
		guard monitor == nil else {
			return
		}

		monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
			focusList(under: event)
			return event
		}
	}

	/// Exposed so the behaviour can be exercised without a real mouse.
	static func focusList(under event: NSEvent) {
		guard let window = event.window, let content = window.contentView else {
			return
		}

		let point = content.convert(event.locationInWindow, from: nil)
		guard let hit = content.hitTest(point), let list = enclosingList(of: hit) else {
			return
		}

		guard window.firstResponder !== list else {
			return
		}

		window.makeFirstResponder(list)
	}

	private static func enclosingList(of view: NSView) -> NSTableView? {
		var current: NSView? = view
		while let candidate = current {
			if let table = candidate as? NSTableView {
				return table
			}
			current = candidate.superview
		}
		return nil
	}
}
#endif
