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
		
		let broker = borkerCell(of: alias)
		if broker.exists {
			#if targetEnvironment(macCatalyst)
			app.launchMenuAction(
				on: broker,
				label: "Delete broker"
			)
			#else
			broker.swipeLeft()
			app.buttons["Delete"].tap()
			#endif
		}
	}
	
	func confirmDelete() {
		app.buttons["Delete"].tap()
	}
	
	func cancelDelete(alias: String) {
		#if targetEnvironment(macCatalyst)
		app.typeKey("\u{1B}", modifierFlags: [])
		#else
		app.buttons["Cancel"].tap()
		#endif
	}
	
	func create(broker: Broker) {
		app.buttons["Add Broker"].tap()
		
		if let alias = broker.alias {
			let aliasField = app.textFields["alias"]
			aliasField.tap()
			aliasField.typeText("\(alias)\n")
		}
		
		if let hostname = broker.hostname {
			let hostField = app.textFields["hostname"]
			hostField.tap()
			hostField.typeText("\(hostname)\n")
		}
		
		snapshot(ScreenshotIds.CONFIG)
		app.buttons["Save"].tap()
	}
	
	func edit(alias oldName: String, broker: Broker) {
		app.launchMenuAction(
			on: borkerCell(of: oldName),
			label: "Edit"
		)
		
		if let alias = broker.alias {
			let aliasField = app.textFields["alias"]
			aliasField.clearAndEnterText(text: "\(alias)\n")
		}
		
		if let hostname = broker.hostname {
			let hostField = app.textFields["hostname"]
			hostField.clearAndEnterText(text: "\(hostname)\n")
		}
		
		app.buttons["Save"].tap()
	}
	
	func createBasedOn(alias oldName: String, broker: Broker) {
		app.launchMenuAction(
			on: borkerCell(of: oldName),
			label: "Create new based on this"
		)
		
		if let alias = broker.alias {
			let aliasField = app.textFields["alias"]
			guard let stringValue = aliasField.value as? String else {
				XCTFail("No string vlaue found")
				return
			}
			
			XCTAssertEqual(oldName, stringValue)
			aliasField.clearAndEnterText(text: "\(alias)\n")
		}
		
		if let hostname = broker.hostname {
			let hostField = app.textFields["hostname"]
			hostField.clearAndEnterText(text: "\(hostname)\n")
		}
		
		app.buttons["Save"].tap()
	}
	
	func start(alias: String) {
		borkerCell(of: alias).tap()
		
		#if targetEnvironment(macCatalyst)
		app.buttons["Play"].tap()
		#endif
	}
	
	func borkerCell(of alias: String) -> XCUIElement {
		return app.cells["broker: \(alias)"]
	}
}
