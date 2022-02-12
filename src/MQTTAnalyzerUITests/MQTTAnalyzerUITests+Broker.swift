//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension MQTTAnalyzerUITests {
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
}
