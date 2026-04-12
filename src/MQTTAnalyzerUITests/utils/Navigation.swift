//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import XCTest

class Navigation {
	let app: XCUIApplication
	let alias: String
	var currentFolder: [String] = []

	/// Returns true if running on iPad with three-column layout (no folder navigation)
	var isThreeColumnLayout: Bool {
		#if os(macOS)
		return true
		#else
		return UIDevice.current.userInterfaceIdiom == .pad
		#endif
	}

	init(app: XCUIApplication, alias: String) {
		self.app = app
		self.alias = alias
	}

	class func id(suffix: String = "/") -> String {
		return String.random(length: 8) + suffix
	}

	class func idSmall(suffix: String = "/") -> String {
		return String.random(length: 3) + suffix
	}

	func navigateToBrokers() {
		if isThreeColumnLayout {
			// iPad three-column: show the sidebar (brokers list) by tapping the sidebar toggle
			let sidebarButton = app.buttons["Show Sidebar"].firstMatch
			if sidebarButton.waitForExistence(timeout: 3) && sidebarButton.isHittable {
				sidebarButton.tap()
			}
			currentFolder = []
		} else {
			navigate(to: "")
			_navigateUp()
		}
	}

	func groupCell(topic: String) -> XCUIElement {
		let identifier = "group: \(topic)"
		return app.descendants(matching: .any)[identifier].firstMatch
	}

	func openMessageGroup() {
		if isThreeColumnLayout {
			// iPad three-column: messages are already shown in detail column after selecting topic
			// Just update tracking
			currentFolder.append("messages")
		} else {
			// iPhone two-column: tap the group cell to see messages
			groupCell(topic: currentFolder.joined(separator: "/")).tap()
			currentFolder.append("messages")
		}
	}

	func openMessage() {
		let button = app.descendants(matching: .any)["message"].firstMatch

		if isThreeColumnLayout {
			// iPad three-column: scroll within the messages list in the detail column
			let messagesList = app.descendants(matching: .any)["messages-list"].firstMatch
			if messagesList.waitForExistence(timeout: 5) {
				app.scrollToElementInContainer(element: button, container: messagesList)
			}
		} else {
			// iPhone: scroll within the app
			app.scrollToElement(element: button)
		}

		button.tap()
		currentFolder.append("message")
	}

	/// Navigate back to the root topics view
	func navigateToRoot() {
		if isThreeColumnLayout {
			// iPad three-column: just clear the current folder tracking
			// No actual navigation needed - tree is always visible
			currentFolder = []
		} else {
			while !currentFolder.isEmpty {
				navigateUp()
			}
		}
	}

	func navigate(to topic: String) {
		let split = topic.split(separator: "/").map { String($0) }

		if isThreeColumnLayout {
			// iPad three-column: expand tree nodes and select the target
			navigateTreeColumn(to: topic, split: split)
		} else {
			// iPhone two-column: navigate folder-by-folder
			while !split.starts(with: currentFolder) {
				navigateUp()
			}

			for i in currentFolder.count ..< split.count {
				open(topic: split[0...i].joined(separator: "/"))
			}

			currentFolder = split
		}
	}

	/// Navigate in three-column layout by expanding tree and selecting topic
	private func navigateTreeColumn(to topic: String, split: [String]) {
		guard !split.isEmpty else {
			currentFolder = []
			return
		}

		// Expand all parent nodes to reveal the target
		for i in 0 ..< split.count - 1 {
			let parentTopic = split[0...i].joined(separator: "/")
			let parentCell = app.elementContainingIdentifier("folder: \(parentTopic)")
			if parentCell.waitForExistence(timeout: 5) {
				// Check if already expanded by looking for child
				let childTopic = split[0...i+1].joined(separator: "/")
				let childCell = app.elementContainingIdentifier("folder: \(childTopic)")
				if !childCell.exists {
					// Need to expand - tap the disclosure button
					expandTreeNode(topic: parentTopic)
					// Wait for child to appear
					_ = childCell.waitForExistence(timeout: 3)
				}
			}
		}

		// Select the target topic
		let targetCell = app.elementContainingIdentifier("folder: \(topic)")
		XCTAssertTrue(targetCell.waitForExistence(timeout: 5), "Expected folder \(topic) to exist")
		targetCell.tap()

		currentFolder = split
	}

	func navigateUp() {
		// Don't navigate up if we're already at root
		guard !currentFolder.isEmpty else { return }

		_navigateUp()
	}

	func _navigateUp() {
		if isThreeColumnLayout {
			// iPad three-column: no navigation, just update tracking
			currentFolder = Array(currentFolder.dropLast())
		} else {
			// iPhone two-column: use Back button
			let backButton = app.navigationBars.buttons["Back"]
			if backButton.exists {
				backButton.tap()
			} else {
				// Try the first button in the navigation bar (usually back button)
				let firstNavButton = app.navigationBars.buttons.element(boundBy: 0)
				if firstNavButton.exists {
					firstNavButton.tap()
				}
			}

			// Update currentFolder
			currentFolder = Array(currentFolder.dropLast())
		}
	}

	private func open(topic: String) {
		folderCell(topic: topic).tap()
	}

	func folderCell(topic: String) -> XCUIElement {
		let cell = app.elementContainingIdentifier("folder: \(topic)")
		XCTAssertTrue(cell.waitForExistence(timeout: 5), "Expected folder cell \(topic) to exist")
		return cell
	}

	/// Returns the tree node cell element for a given topic
	func treeNodeCell(topic: String) -> XCUIElement {
		let identifier = "tree-node: \(topic)"
		let cell = app.descendants(matching: .any)[identifier].firstMatch
		XCTAssertTrue(cell.waitForExistence(timeout: 5), "Expected tree node cell \(topic) to exist")
		return cell
	}

	/// Expands a tree node to reveal its children.
	/// Automatically expands parent nodes if needed.
	/// Only expands nodes that aren't already expanded (checks if children are visible).
	func expandTreeNode(topic: String) {
		let parts = topic.split(separator: "/").map { String($0) }
		guard !parts.isEmpty else { return }

		// Expand each level, checking if children are already visible
		for i in 0..<parts.count {
			let currentPath = parts[0...i].joined(separator: "/")
			let folder = app.elementContainingIdentifier("folder: \(currentPath)")

			// Make sure this node is visible (expand parent if needed)
			if !folder.exists {
				// This shouldn't happen if we're iterating in order, but handle it
				continue
			}

			// Check if this node needs to be expanded by looking for any child
			// We look for any folder that starts with currentPath/
			let childPrefix = "folder: \(currentPath)/"
			let anyChild = app.descendants(matching: .any).matching(
				NSPredicate(format: "identifier BEGINSWITH %@", childPrefix)
			).firstMatch

			if !anyChild.exists {
				// Children not visible, need to expand
				tapChevron(topic: currentPath)
				// Wait a moment for children to appear
				Thread.sleep(forTimeInterval: 0.3)
			}
		}
	}

	/// Taps the chevron of a tree node (internal helper)
	private func tapChevron(topic: String) {
		let folder = app.elementContainingIdentifier("folder: \(topic)")
		guard folder.waitForExistence(timeout: 5) else { return }

		#if os(macOS)
		// On macOS, find the disclosure triangle near this folder element
		// The disclosure triangle shares the same Y position in the outline view
		let folderFrame = folder.frame
		let disclosures = app.disclosureTriangles.allElementsBoundByIndex
		for disclosure in disclosures {
			if disclosure.exists && abs(disclosure.frame.midY - folderFrame.midY) < 5 {
				disclosure.tap()
				return
			}
		}
		// Fallback: double-click the folder to toggle expansion
		folder.doubleClick()
		#else
		let cellFrame = folder.frame
		let tapPoint = CGPoint(x: cellFrame.maxX - 20, y: cellFrame.midY)
		app.coordinate(withNormalizedOffset: .zero)
			.withOffset(CGVector(dx: tapPoint.x, dy: tapPoint.y))
			.tap()
		#endif
	}

	func flatView(tc: XCTestCase) {
		#if os(macOS)
		app.checkBoxes["flatview"].click()
		#else
		let flatview = app.switches["flatview"]
		// On iPad three-column layout, flatview doesn't exist - skip silently
		if flatview.waitForExistence(timeout: 2) {
			tc.turnSwitchOn(flatview)
		}
		#endif
	}

	func flatViewOff(tc: XCTestCase) {
		#if os(macOS)
		app.checkBoxes["flatview"].click()
		#else
		let flatview = app.switches["flatview"]
		// On iPad three-column layout, flatview doesn't exist - skip silently
		if flatview.exists {
			tc.turnSwitchOff(flatview)
		}
		#endif
	}

	/// Opens the publish dialog using the Publish button in the toolbar
	func openPublishDialog() {
		let publishButton = app.buttons["Publish"]

		if publishButton.waitForExistence(timeout: 2) && publishButton.isHittable {
			// Publish button is directly visible in toolbar
			publishButton.tap()
		} else {
			// Publish button is in the "More" overflow menu (narrow column on iPad)
			let moreButton = app.buttons["More"].firstMatch
			XCTAssertTrue(moreButton.waitForExistence(timeout: 3), "Expected More button in toolbar")
			moreButton.tap()

			// Now tap Publish in the overflow menu
			let publishInMenu = app.buttons["Publish"].firstMatch
			XCTAssertTrue(publishInMenu.waitForExistence(timeout: 3), "Expected Publish button in overflow menu")
			publishInMenu.tap()
		}
	}

	@MainActor func publishNew(topic: String) {
		let groupCell = app.elementContainingIdentifier("folder: \(topic)")
		XCTAssertTrue(groupCell.waitForExistence(timeout: 5), "Expected folder cell \(topic) to exist")

		// Scroll to make sure the cell is visible
		#if !os(macOS)
		app.scrollToElement(element: groupCell)
		#endif

		#if os(macOS)
		groupCell.rightClick()
		// Context menu has a "Publish" submenu containing "New message"
		let publishMenu = app.menuItems["Publish"]
		if publishMenu.waitForExistence(timeout: 3) {
			publishMenu.tap()
			let newMessage = app.menuItems["New message"]
			if newMessage.waitForExistence(timeout: 3) {
				snapshot(ScreenshotIds.CONTEXT_MENU)
				newMessage.tap()
			}
		}
		#else
		// Long press on the LEFT side of the cell to avoid hitting the chevron (which would collapse the tree)
		let cellFrame = groupCell.frame
		let pressPoint = CGPoint(x: cellFrame.minX + 50, y: cellFrame.midY)
		let coordinate = app.coordinate(withNormalizedOffset: .zero)
			.withOffset(CGVector(dx: pressPoint.x, dy: pressPoint.y))
		coordinate.press(forDuration: 1.0)

		// Small wait for context menu animation
		Thread.sleep(forTimeInterval: 0.5)

		// Context menu items can appear as various element types
		// Try multiple approaches to find the Publish menu
		let publishById = app.descendants(matching: .any)["publish"].firstMatch
		let publishByLabel = app.buttons["Publish"].firstMatch
		let publishByStaticText = app.staticTexts["Publish"].firstMatch

		var publishMenu: XCUIElement?
		if publishById.waitForExistence(timeout: 2) {
			publishMenu = publishById
		} else if publishByLabel.exists {
			publishMenu = publishByLabel
		} else if publishByStaticText.exists {
			publishMenu = publishByStaticText
		}

		XCTAssertNotNil(publishMenu, "Expected publish menu in context menu")
		snapshot(ScreenshotIds.CONTEXT_MENU_COPY)
		publishMenu?.tap()

		// Wait for submenu to appear
		let newMsgById = app.descendants(matching: .any)["publish new"].firstMatch
		let newMsgByLabel = app.buttons["New message"].firstMatch
		let newMsgByStaticText = app.staticTexts["New message"].firstMatch

		var publishNewButton: XCUIElement?
		if newMsgById.waitForExistence(timeout: 2) {
			publishNewButton = newMsgById
		} else if newMsgByLabel.exists {
			publishNewButton = newMsgByLabel
		} else if newMsgByStaticText.exists {
			publishNewButton = newMsgByStaticText
		}

		XCTAssertNotNil(publishNewButton, "Expected publish new button")
		snapshot(ScreenshotIds.CONTEXT_MENU)
		publishNewButton?.tap()
		#endif

		#if os(macOS)
		let setButton = app.radioButtons["set"]
		#else
		let setButton = app.buttons["set"]
		#endif
		XCTAssertTrue(setButton.waitForExistence(timeout: 3), "Expected set button in topic picker")
		setButton.tap()
		snapshot(ScreenshotIds.PUBLISH)

		// Submit the publish dialog
		#if os(macOS)
		// On macOS, the sheet may not have a navigation bar — look for the Publish button directly
		let publishButton = app.buttons["Publish"].firstMatch
		XCTAssertTrue(publishButton.waitForExistence(timeout: 3), "Expected Publish button")
		publishButton.tap()
		#else
		app.navigationBars["Publish message"].buttons["Publish"].tap()
		#endif
	}
}
