//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

struct Credentials {
	var username: String?
	var password: String?
}

class Brokers {
	let app: XCUIApplication
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func delete(alias: String) {
		if !app.staticTexts["Brokers"].exists {
			XCTFail("Expected to be on the broker page")
		}
		
		app.launchMenuAction(
			on: brokerCell(of: alias),
			label: "Edit"
		)
		
		app.buttons["delete-broker"].tap()
	}
	
	func confirmDelete() {
		app.buttons["Delete"].tap()
	}
	
	func cancelDelete(alias: String) {
		#if targetEnvironment(macCatalyst)
		app.typeKey("\u{1B}", modifierFlags: [])
		#else
		app.staticTexts["Port"].tap()
		#endif
		app.buttons["Cancel"].tap()
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

		if let port = broker.port {
			let portField = app.textFields["port"]
			portField.tap()
			portField.clearAndEnterText(text: "\(port)")
		}
		
		if let proto = broker.connectionProtocol {
			let protoField = app.buttons["\(proto)"]
			protoField.tap()
		}
		
		if let authType = broker.authType {
			let protoField = app.buttons["\(authType)-auth"]
			protoField.tap()
			
			if authType == .userPassword {
				if let username = broker.username {
					let field = app.textFields["username"]
					field.tap()
					field.clearAndEnterText(text: username)
				}
				
				if let password = broker.password {
					let field = app.secureTextFields["password"]
					field.tap()
					field.clearAndEnterText(text: password)
				}
			}
		}
		
		snapshot(ScreenshotIds.CONFIG)
		app.buttons["Save"].tap()
	}
	
	func edit(alias oldName: String, broker: Broker) {
		app.launchMenuAction(
			on: brokerCell(of: oldName),
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
			on: brokerCell(of: oldName),
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
	
	func start(alias: String, waitConnected: Bool = true) {
		brokerCell(of: alias).tap()
		
		#if targetEnvironment(macCatalyst)
		app.buttons["Play"].tap()
		#endif
		
		if waitConnected {
			waitUntilConnected()
		}
	}
	
	func waitUntilConnected() {
		let flatView: XCUIElement
		#if targetEnvironment(macCatalyst)
		flatView = app.checkBoxes["flatview"]
		#else
		flatView = app.switches["flatview"]
		#endif
		for _ in (0 ... 3) {
			if flatView.waitForExistence(timeout: 1) {
				return
			}
			if self.app.staticTexts["wait_messages"]
				.waitForExistence(timeout: 2) {
				return
			}
		}
	}
	
	func login(credentials: Credentials) {
		XCTAssertTrue(app.staticTexts["Login"].waitForExistence(timeout: 2))
		
		if let username = credentials.username {
			let field = app.textFields["username"]
			field.tap()
			field.typeText(username)
		}

		if let password = credentials.password {
			let field = app.secureTextFields["password"]
			field.tap()
			field.typeText(password)
		}
		
		app.buttons["Login"].tap()
	}
	
	func brokerCell(of alias: String) -> XCUIElement {
		return app.cells["broker: \(alias)"]
	}
}
