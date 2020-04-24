//
//  MQTTAnalyzerUITests.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 09.03.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import XCTest

class MQTTAnalyzerUITests: XCTestCase {
	var app: XCUIApplication!
	
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test.
		app = XCUIApplication()
		
		// We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--uitesting")
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAbout() {
//		app.launch()
//
//		let button = app.otherElements["about.logo"]
//		XCTAssertFalse(button.exists)
//
//		app.buttons["About"].tap()
//		XCUIApplication().navigationBars["Servers"].buttons["About"].tap()
//
//		XCTAssertTrue(button.exists)
//		button.swipeDown()
    }

	func test_rec() {
		
		app.launch()
		app.buttons["About"].tap()
		print(app.accessibilityElements)
//		app
//			.children(matching: .window)
//			.element(boundBy: 0)
//			.children(matching: .other)
//			.element.children(matching: .other)
//			.element(boundBy: 1)
//			.children(matching: .other).element.tap()
		
	}
	
	
    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
