//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension MQTTAnalyzerUITests {
	func testAbout() {
		app.launch()
		
		app.buttons["About"].tap()
		awaitAppear(element: app.staticTexts["about-label"])
		app.buttons["Close"].tap()
		awaitDisappear(element: app.staticTexts["about-label"])
	}
}
