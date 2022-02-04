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
		setupSnapshot(app)
		
		// We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--uitesting")
		app.launchArguments.append("--no-welcome")
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAbout() {
		app.launch()
		
		app.buttons["About"].tap()
		app.buttons["Close"].tap()
    }
	
	func deleteBroker(_ alias: String) {
		let broker = app.cells["broker: \(alias)"]
		if broker.exists {
			broker.swipeLeft()
			app.buttons["Delete"].tap()
		}
	}
	
    func testAdd() {
		let brokers = Brokers(app: app)
		
		let hostname = "192.168.3.50"
		let alias = "Example"
		
		app.launch()
		brokers.delete(alias: alias)
		brokers.create(alias: alias, hostname: hostname)
		brokers.start(alias: alias)
		
		let folders = TopicFolders(app: app)
		folders.navigate(to: "hue/light")
		snapshot("1 Lights")
    }
	
//    func testLaunchPerformance() {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
