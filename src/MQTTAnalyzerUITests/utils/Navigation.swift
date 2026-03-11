//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import UIKit
import XCTest

class Navigation {
	let app: XCUIApplication
	let alias: String
	var currentFolder: [String] = []

	/// Returns true if running on iPad with three-column layout (no folder navigation)
	var isThreeColumnLayout: Bool {
		// On iPad, we use three-column NavigationSplitView layout
		// Check device idiom directly instead of relying on UI elements that may be hidden
		return UIDevice.current.userInterfaceIdiom == .pad
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
		navigate(to: "")
		
		navigateUp()
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
		// Expand all parent nodes to reveal the target
		for i in 0 ..< split.count - 1 {
			let parentTopic = split[0...i].joined(separator: "/")
			let parentCell = app.descendants(matching: .any)["folder: \(parentTopic)"].firstMatch
			if parentCell.waitForExistence(timeout: 5) {
				// Check if already expanded by looking for child
				let childTopic = split[0...i+1].joined(separator: "/")
				let childCell = app.descendants(matching: .any)["folder: \(childTopic)"].firstMatch
				if !childCell.exists {
					// Need to expand - tap the disclosure button
					expandTreeNode(topic: parentTopic)
					// Wait for child to appear
					_ = childCell.waitForExistence(timeout: 3)
				}
			}
		}

		// Select the target topic
		let targetCell = app.descendants(matching: .any)["folder: \(topic)"].firstMatch
		XCTAssertTrue(targetCell.waitForExistence(timeout: 5), "Expected folder \(topic) to exist")
		targetCell.tap()

		currentFolder = split
	}
	
	func navigateUp() {
		// Don't navigate up if we're already at root
		guard !currentFolder.isEmpty else { return }

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
		let identifier = "folder: \(topic)"
		let cell = app.descendants(matching: .any)[identifier].firstMatch
		XCTAssertTrue(cell.waitForExistence(timeout: 10), "Expected folder cell \(topic) to exist")
		return cell
	}

	/// Returns the tree node cell element for a given topic
	func treeNodeCell(topic: String) -> XCUIElement {
		let identifier = "tree-node: \(topic)"
		let cell = app.descendants(matching: .any)[identifier].firstMatch
		XCTAssertTrue(cell.waitForExistence(timeout: 10), "Expected tree node cell \(topic) to exist")
		return cell
	}

	/// Expands a tree node by tapping its disclosure button (chevron)
	/// This shows children inline instead of navigating into the folder
	func expandTreeNode(topic: String) {
		let folderIdentifier = "folder: \(topic)"
		let folder = app.descendants(matching: .any)[folderIdentifier].firstMatch
		XCTAssertTrue(folder.waitForExistence(timeout: 10), "Expected folder \(topic) to exist")

		// Tap the chevron which is on the right side of the cell
		let cellFrame = folder.frame
		let tapPoint = CGPoint(x: cellFrame.maxX - 20, y: cellFrame.midY)
		app.coordinate(withNormalizedOffset: .zero)
			.withOffset(CGVector(dx: tapPoint.x, dy: tapPoint.y))
			.tap()
	}
	
	func flatView(tc: XCTestCase) {
		#if targetEnvironment(macCatalyst)
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
		#if targetEnvironment(macCatalyst)
		app.checkBoxes["flatview"].click()
		#else
		let flatview = app.switches["flatview"]
		// On iPad three-column layout, flatview doesn't exist - skip silently
		if flatview.exists {
			tc.turnSwitchOff(flatview)
		}
		#endif
	}
	
	/// Opens the publish dialog using the Send button in the toolbar
	func openPublishDialog() {
		let sendButton = app.buttons["Send"]

		if sendButton.waitForExistence(timeout: 2) && sendButton.isHittable {
			// Send button is directly visible in toolbar
			sendButton.tap()
		} else {
			// Send button is in the "More" overflow menu (narrow column on iPad)
			let moreButton = app.buttons["More"].firstMatch
			XCTAssertTrue(moreButton.waitForExistence(timeout: 3), "Expected More button in toolbar")
			moreButton.tap()

			// Now tap Send in the overflow menu
			let sendInMenu = app.buttons["Send"].firstMatch
			XCTAssertTrue(sendInMenu.waitForExistence(timeout: 3), "Expected Send button in overflow menu")
			sendInMenu.tap()
		}
	}

	@MainActor func publishNew(topic: String) {
		let groupCell = app.descendants(matching: .any)["group: \(topic)"].firstMatch
		XCTAssertTrue(groupCell.waitForExistence(timeout: 5), "Expected group cell \(topic) to exist")

		// Scroll to make sure the cell is visible
		app.scrollToElement(element: groupCell)

		#if targetEnvironment(macCatalyst)
		groupCell.rightClick()
		app.menuItems["Publish new message"].tap()
		#else
		// Long press to open context menu
		groupCell.press(forDuration: 1.0)

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

		let setButton = app.buttons["set"]
		XCTAssertTrue(setButton.waitForExistence(timeout: 3), "Expected set button in topic picker")
		setButton.tap()
		snapshot(ScreenshotIds.PUBLISH)

		// Submit the publish dialog
		app.buttons["Publish"].tap()
	}
}
