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
		
		#if targetEnvironment(macCatalyst)
		Snapshot.cacheDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
		#endif
        app.launchArguments.append("--ui-testing")
		app.launchArguments.append("--no-welcome")
		app.launch()
		
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAbout() {
		app.launch()
		
		app.buttons["About"].tap()
		awaitAppear(element: app.staticTexts["MQTTAnalyzer"])
		app.buttons["Close"].tap()
		awaitDisappear(element: app.staticTexts["MQTTAnalyzer"])
    }
	
	func testDeleteBroker() {
		let alias = "Example"

		let brokers = Brokers(app: app)
		
		app.launch()
		
		let example = brokers.borkerCell(of: alias)
		awaitAppear(element: example)
		brokers.delete(alias: alias)
		awaitDisappear(element: example)
	}
	
	func testRenameBroker() {
		let alias = "Example"
		let newAlias = "Example-Renamed"
		
		let brokers = Brokers(app: app)
		
		app.launch()
		
		let old = brokers.borkerCell(of: alias)
		awaitAppear(element: old)
		brokers.edit(alias: alias, broker: Broker(alias: newAlias, hostname: nil))
		awaitDisappear(element: app.staticTexts[alias])
		awaitAppear(element: app.staticTexts[newAlias])
	}
	
	func testCreateNewBrokerBasedOnOld() {
		let alias = "Example"
		let newAlias = "Example-Derived"
		
		let brokers = Brokers(app: app)
		
		app.launch()
		
		brokers.createBasedOn(alias: alias, broker: Broker(alias: newAlias, hostname: "other-hostname"))
		awaitAppear(element: app.staticTexts["Example"])
		awaitAppear(element: app.staticTexts["Example-Derived"])
		awaitAppear(element: app.staticTexts["other-hostname"])
	}
	
	//  ~/Library/Containers/de.rnd7.MQTTAnalyzerUITests.xctrunner/Data/screenshots
    func testFullRoundtrip() {
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		let brokers = Brokers(app: app)
		
		app.launch()
		examples.publish()
		snapshot(ScreenshotIds.BROKERS)
		
		let nav = Navigation(app: app, alias: alias)
		
		brokers.delete(alias: alias)
		brokers.create(broker: Broker(alias: alias, hostname: hostname))
		snapshot(ScreenshotIds.BROKERS)
		brokers.start(alias: alias)
		
		nav.navigate(to: "home/dishwasher/000123456789")
		nav.openMessageGroup()
		snapshot(ScreenshotIds.JSON_DATA)
		
		nav.navigate(to: "home/dishwasher/000123456789/full")
		nav.openMessageGroup()
		nav.openMessage()
		snapshot(ScreenshotIds.JSON_DETAILS)
		
		nav.navigate(to: "hue")
		nav.flatView()
		snapshot(ScreenshotIds.FLAT_VIEW)
		nav.flatView()

		nav.navigate(to: "hue/light/kitchen")
		snapshot(ScreenshotIds.LIGHTS)
		
		nav.publishNew(topic: "hue/light/kitchen/coffee-spot")
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
