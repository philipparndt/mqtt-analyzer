//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension MQTTAnalyzerUITests {
	func testFlatView() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "home")
		
		let cell = nav.groupCell(topic: "home/contacts/frontdoor")
		
		awaitDisappear(element: cell)
		nav.flatView()
		awaitAppear(element: cell)
	}
}
