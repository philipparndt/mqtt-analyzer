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
		let brokersTitle = app.staticTexts["Brokers"]
		if !brokersTitle.waitForExistence(timeout: 5) {
			XCTFail("Expected to be on the broker page")
		}
		
		app.launchMenuAction(
			on: brokerCell(of: alias),
			identifier: "edit-broker"
		)

		let button = app.buttons["delete-broker"]
		app.scrollToElement(element: button)
		button.tap()
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
	
	@MainActor func create(broker: Broker, tc: XCTestCase) {
		app.buttons["Add Broker"].tap()
		
		if let alias = broker.alias {
			let field = app.textFields["alias"]
			field.tap()
			field.typeText("\(alias)\n")
		}
		
		if let hostname = broker.hostname {
			let field = app.textFields["hostname"]
			field.tap()
			field.typeText("\(hostname)\n")
		}

		if let port = broker.port {
			if port != 1883 {
				let field = app.textFields["port"]
				field.tap()
				field.clearAndEnterText(text: "\(port)")
				// Dismiss the number pad keyboard via the Done button
				let doneButton = app.toolbars.buttons["Done"]
				if doneButton.exists {
					doneButton.tap()
				}
			}
		}
		
		if let proto = broker.connectionProtocol {
			let field = app.buttons["\(proto)"]
			field.tap()
		}
		
		if let version = broker.protocolVersion {
			let field = app.buttons["\(version)"]
			field.tap()
		}
		
		if let tls = broker.tls {
			if tls {
				#if targetEnvironment(macCatalyst)
				let field = app.checkBoxes["tls"]
				field.click()
				#else
				let field = app.switches["tls"]
				tc.turnSwitchOn(field)
				#endif
			}
		}
		
		if let authType = broker.authType {
			let field = app.switches["\(authType)-auth"]
			app.switches["tls"].scrollToElement(element: field)
			tc.turnSwitchOn(field)
			
			if authType == .userPassword {
				if let username = broker.username {
					let field = app.textFields["username"]
					field.tap()
					field.typeText(username)
				}

				if let password = broker.password {
					let field = app.secureTextFields["password"]
					field.tap()
					field.typeText(password)
					// Dismiss keyboard to ensure password is committed
					app.keyboards.buttons["return"].tap()
				}
			}
		}

		snapshot(ScreenshotIds.CONFIG)
		// Give the form a moment to save field values
		Thread.sleep(forTimeInterval: 0.5)
		app.buttons["Save"].tap()

		// Handle iOS password save dialog if it appears
		let notNowButton = app.buttons["Not Now"]
		if notNowButton.waitForExistence(timeout: 2) {
			notNowButton.tap()
		}
	}
	
	func startEdit(alias oldName: String) {
		app.launchMenuAction(
			on: brokerCell(of: oldName),
			identifier: "edit-broker"
		)
	}
	
	func save() {
		app.buttons["Save"].tap()
	}
	
	func edit(alias oldName: String, broker: Broker) {
		startEdit(alias: oldName)
		
		if let alias = broker.alias {
			let aliasField = app.textFields["alias"]
			aliasField.clearAndEnterText(text: "\(alias)\n")
		}
		
		if let hostname = broker.hostname {
			let hostField = app.textFields["hostname"]
			hostField.clearAndEnterText(text: "\(hostname)\n")
		}
		
		save()
	}
	
	func addSubscription(alias: String, topic: String) {
		startEdit(alias: alias)
		addSubscriptionToCurrentBroker(topic: topic)
		app.buttons["Save"].tap()
		save()
	}
	
	func addSubscriptionToCurrentBroker(topic: String) {
		app.buttons["add-subscription"].tap()
		let field = app.textFields["subscription-topic"]
		XCTAssertTrue(field.waitForExistence(timeout: 4), "Expected add-subscription button to be there")
		field.tap()
		field.clearAndEnterText(text: topic)
		app.buttons["Edit broker"].tap()
	}
	
	func deleteSubscriptionFromCurrentBroker(topic: String) {
		app.buttons[topic].tap()
		let button = app.buttons["Delete"]
		XCTAssertTrue(button.waitForExistence(timeout: 4), "Expected delete button to be there")
		button.tap()
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
		let waitMessages = app.staticTexts["wait_messages"]
		let waitMessagesText = app.staticTexts["Waiting for messages..."]
		let noTopicsText = app.staticTexts["No Topics"]
		let connectingText = app.staticTexts["Connecting..."]
		let loginView = app.staticTexts["Login"]
		// On iPad three-column layout, check for tree_wait_messages or Publish button in toolbar
		let treeWaitMessages = app.descendants(matching: .any)["tree_wait_messages"].firstMatch
		let publishButton = app.buttons["Publish"]

		// Wait up to 15 seconds for connection indicators
		for _ in 0 ..< 5 {
			if flatView.waitForExistence(timeout: 1) {
				return
			}
			// Check various indicators that we're connected or connecting
			if waitMessages.exists || waitMessagesText.exists || noTopicsText.exists {
				return
			}
			// On iPad, the Publish button appears in TopicTreeSidebarView toolbar when connected
			if publishButton.exists || treeWaitMessages.exists {
				return
			}
			if connectingText.waitForExistence(timeout: 2) {
				// Still connecting, keep waiting
				continue
			}
			// Check if login dialog appeared (credentials might not be saved properly)
			if loginView.exists {
				XCTFail("Login dialog appeared - credentials may not have been saved correctly")
				return
			}
		}
		XCTFail("Expected to be connected (flatview switch or wait_messages text should be visible)")
	}
	
	func login(credentials: Credentials) {
		XCTAssertTrue(app.staticTexts["Login"].waitForExistence(timeout: 2), "Expected Login to be there")

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

		// Handle iOS password save dialog if it appears after login
		let notNowButton = app.buttons["Not Now"]
		if notNowButton.waitForExistence(timeout: 2) {
			notNowButton.tap()
		}
	}
	
	func openDiagnostics(alias: String) {
		app.launchMenuAction(
			on: brokerCell(of: alias),
			label: "Diagnose"
		)
	}

	func brokerCell(of alias: String) -> XCUIElement {
		let identifier = "broker: \(alias)"
		// Use descendants query with firstMatch to find the element regardless of type
		let element = app.descendants(matching: .any)[identifier].firstMatch
		XCTAssertTrue(element.waitForExistence(timeout: 4), "Expected brokerCell \(alias) to be there")
		return element
	}
}
