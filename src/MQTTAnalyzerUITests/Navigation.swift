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
	
	func navigateToBrokers() {
		navigate(to: "")
		
		navigateUp()
	}
	
	func openMessageGroup() {
		let groupName = "group: \(currentFolder.joined(separator: "/"))"
		app.cells[groupName].tap()
		currentFolder.append(currentFolder[currentFolder.count - 1])
	}
	
	func openMessage() {
		app.cells["message"].tap()
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
		app.cells["folder: \(topic)"].tap()
	}
	
	func flatView() {
		#if targetEnvironment(macCatalyst)
		app.checkBoxes["flatview"].click()
		#else
		app.switches["flatview"].tap()
		#endif
	}
	
	func publishNew(topic: String) {
		#if targetEnvironment(macCatalyst)
		app.cells["group: \(topic)"].rightClick()
		#else
		app.cells["group: \(topic)"].press(forDuration: 1)
		#endif
		
		snapshot(ScreenshotIds.CONTEXT_MENU)
		
		#if targetEnvironment(macCatalyst)
		app.menuItems["Publish new message"].tap()
		#else
		app.buttons["publish new"].tap()
		#endif
		app.buttons["set"].tap()
		snapshot(ScreenshotIds.PUBLISH)
		
		app.buttons["Publish"].tap()
	}
}
