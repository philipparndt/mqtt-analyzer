//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

class Brokers {
	let app: XCUIApplication
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func delete(alias: String) {
		if !app.staticTexts["Brokers"].exists {
			XCTFail("Expected to be on the broker page")
		}
		
		let broker = app.cells["broker: \(alias)"]
		if broker.exists {
			broker.swipeLeft()
			app.buttons["Delete"].tap()
		}
	}
	
	func create(alias: String, hostname: String) {
		app.buttons["Add Broker"].tap()
		
		let aliasField = app.textFields["alias"]
		aliasField.tap()
		aliasField.typeText("\(alias)\n")
		
		let hostField = app.textFields["hostname"]
		hostField.tap()
		hostField.typeText("\(hostname)\n")
		
		snapshot(ScreenshotIds.CONFIG)
		app.buttons["Save"].tap()
	}
	
	func start(alias: String) {
		app.cells["broker: \(alias)"].tap()
	}
}
