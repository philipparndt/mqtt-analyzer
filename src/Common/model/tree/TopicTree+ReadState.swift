//
//  TreeModel.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	var readStateCombined: Bool {
		if !readState.read {
			return false
		}

		let result = children.values
			.map { $0.readStateCombined }
			.contains { !$0 }

		return result
	}

	func markRead() {
		setRead(true)

		for child in children.values {
			child.markRead()
		}
	}

	func markUnread() {
		// Marking always walks up to the root, so an already unread node has
		// already unread parents. Stopping there keeps a message on a known topic
		// from publishing on every node up to the root — the topic list observes
		// the root, and a publish there redraws all of its rows.
		guard setRead(false) else {
			return
		}

		var current = parent
		while let node = current, node.setRead(false) {
			current = node.parent
		}
	}

	func recomputeReadState() {
		if messages.isEmpty && childrenRead() {
			setRead(true)
		}
	}

	/// Assigns the read state, and reports whether that changed anything.
	@discardableResult
	private func setRead(_ read: Bool) -> Bool {
		guard readState.read != read else {
			return false
		}

		readState = Readstate(read: read)
		return true
	}

	func childrenRead() -> Bool {
		return !children.values.contains { node in
			return !node.readState.read
		}
	}
}
