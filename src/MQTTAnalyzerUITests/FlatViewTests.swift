//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class FlatViewTests: AbstractUITests {
	func testFlatView() {
		let brokers = Brokers(app: app)
		
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.id()
		
		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()
		brokers.start(alias: alias)
		examples.publish(prefix: id)
		
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "\(id)home")
		
		let cell = nav.groupCell(topic: "\(id)home/contacts/frontdoor")
		
		awaitDisappear(element: cell)
		nav.flatView(tc: self)
		awaitAppear(element: cell)
	}
}
