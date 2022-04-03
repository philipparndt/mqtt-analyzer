//
//  MQTTAnalyzerUITests.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 09.03.20.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import XCTest

class AbstractUITests: XCTestCase {
	var app: XCUIApplication!
	static var currentApp: XCUIApplication!
	
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test.
		app = XCUIApplication()
		setupSnapshot(app)
		
		#if targetEnvironment(macCatalyst)
		Snapshot.cacheDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
		#endif
		app.launchArguments.append("--ui-testing")
		app.launchArguments.append("--no-welcome")
		app.launch()
		AbstractUITests.currentApp = app
		
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
