//
//  Search.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-26.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

class Search {
	let WHOLE_WORD = "Whole word, whole-word"
	
	let app: XCUIApplication
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func searchFor(text: String) {
		#if targetEnvironment(macCatalyst)
		let searchField = app.searchFields.firstMatch
		searchField.tap()
		searchField.typeText(text)
		#else
		app.swipeDown()
		let searchField = app.searchFields.firstMatch
		searchField.tap()
		searchField.typeText(text)
		#endif
	}
	
	func disableWholeWord() {
		#if targetEnvironment(macCatalyst)
		let whole = app.checkBoxes[WHOLE_WORD]
		if whole.isChecked() {
			whole.click()
		}
		#else
		let whole = app.switches[WHOLE_WORD]
		if whole.isChecked() {
			whole.tap()
		}
		#endif
	}
	
	func enableWholeWord() {
		#if targetEnvironment(macCatalyst)
		let whole = app.checkBoxes[WHOLE_WORD]
		if !whole.isChecked() {
			whole.click()
		}
		#else
		let whole = app.switches[WHOLE_WORD]
		if !whole.isChecked() {
			whole.tap()
		}
		#endif
	}
}
