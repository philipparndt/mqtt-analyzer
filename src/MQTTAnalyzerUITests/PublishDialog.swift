//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

class PublishDialog {
	let app: XCUIApplication
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func open() {
		app.buttons["Send"].tap()
	}
	
	func apply() {
		app.buttons["Publish"].tap()
	}
	
	func fill(topic: String, message: String) {
		let topicText = app.textFields["topic"]
		topicText.tap()
		topicText.clearAndEnterText(text: "topic")
		
		let message = app.textViews["textbox"]
		XCTAssertTrue(message.waitForExistence(timeout: 2))
		message.tap()
		message.typeText("msg")
	}
	
}
