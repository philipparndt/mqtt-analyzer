//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

class Navigation {
	let app: XCUIApplication
	let alias: String
	var currentFolder: [String] = []
	
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
		groupCell(topic: currentFolder.joined(separator: "/")).tap()
		currentFolder.append("messages")
	}

	func openMessage() {
		let button = app.descendants(matching: .any)["message"].firstMatch
		app.scrollToElement(element: button)
		button.tap()
		currentFolder.append("message")
	}

	/// Navigate back to the root topics view
	func navigateToRoot() {
		while !currentFolder.isEmpty {
			navigateUp()
		}
	}
	
	func navigate(to topic: String) {
		let split = topic.split(separator: "/").map { String($0) }
		while !split.starts(with: currentFolder) {
			navigateUp()
		}
				
		for i in currentFolder.count ..< split.count {
			open(topic: split[0...i].joined(separator: "/"))
		}
		
		currentFolder = split
	}
	
	func navigateUp() {
		// Don't navigate up if we're already at root
		guard !currentFolder.isEmpty else { return }

		// Find and tap the Back button in the navigation bar
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
		tc.turnSwitchOn(flatview)
		#endif
	}
	
	func flatViewOff(tc: XCTestCase) {
		#if targetEnvironment(macCatalyst)
		app.checkBoxes["flatview"].click()
		#else
		let flatview = app.switches["flatview"]
		tc.turnSwitchOff(flatview)
		#endif
	}
	
	/// Opens the publish dialog using the Send button in the toolbar
	func openPublishDialog() {
		let sendButton = app.buttons["Send"]
		XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Expected Send button in toolbar")
		sendButton.tap()
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
