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
		let groupName = "group: \(topic)"
		return app.buttons[groupName]
	}
	
	func openMessageGroup() {
		groupCell(topic: currentFolder.joined(separator: "/")).tap()
		currentFolder.append(currentFolder[currentFolder.count - 1])
	}
	
	func openMessage() {
		let button = app.buttons["message"]
		app.scrollToElement(element: button)
		button.tap()
		currentFolder.append("message")
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
		if currentFolder.count - 2 >= 0 {
			let name = currentFolder[currentFolder.count - 2]
			app.buttons[name].tap()
			currentFolder = Array(currentFolder[0...currentFolder.count - 2])
		}
		else if currentFolder.count == 1 {
			app.buttons[self.alias].tap()
			currentFolder = []
		}
		else {
			app.buttons["Brokers"].tap()
		}
	}
	
	private func open(topic: String) {
		folderCell(topic: topic).tap()
	}
	
	func folderCell(topic: String) -> XCUIElement {
		let cell = app.buttons["folder: \(topic)"]
		XCTAssertTrue(cell.waitForExistence(timeout: 10))
		return cell
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
	
	@MainActor func publishNew(topic: String) {
		let groupCell = app.buttons["group: \(topic)"]
		app.openMenu(on: groupCell)
		snapshot(ScreenshotIds.CONTEXT_MENU_COPY)

		#if targetEnvironment(macCatalyst)
		app.menuItems["Publish new message"].tap()
		#else
		app.buttons["Publish"].tap()
		snapshot(ScreenshotIds.CONTEXT_MENU)
		app.buttons["publish new"].tap()
		#endif
		app.buttons["set"].tap()
		snapshot(ScreenshotIds.PUBLISH)
		
		app.buttons["Publish"].tap()
	}
}
