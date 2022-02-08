//
//  XCUIElement+ClearText.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-08.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension XCUIApplication {
	func openMenu(on element: XCUIElement) {
		#if targetEnvironment(macCatalyst)
		element.rightClick()
		#else
		element.press(forDuration: 1)
		#endif
	}
	
	func tapMenuItem(label: String) {
		#if targetEnvironment(macCatalyst)
		menuItems[label].tap()
		#else
		buttons[label].tap()
		#endif
	}
	
	func launchMenuAction(on element: XCUIElement, label: String) {
		openMenu(on: element)
		tapMenuItem(label: label)
	}

}
