//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class SearchTests: AbstractUITests {
	func startSearch(id: String) -> Navigation {
		let brokers = Brokers(app: app)
		
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		
		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()

		brokers.start(alias: alias)
		examples.publish(prefix: id)

		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "\(id)home")
		
		return nav
	}
	
	func testSearch() {
		let id = Navigation.id()
		let nav = startSearch(id: id)
		
		let cell = nav.groupCell(topic: "\(id)home/dishwasher/000123456789")
		awaitDisappear(element: cell)
		
		let search = Search(app: app)
		search.searchFor(text: "running")
		
		awaitAppear(element: cell)
	}
	
	func testToggleWholeWord() {
		let id = Navigation.id()
		let nav = startSearch(id: id)
		
		let cell = nav.groupCell(topic: "\(id)home/dishwasher/000123456789")
		awaitDisappear(element: cell)
		
		let search = Search(app: app)
		search.searchFor(text: "run")
		awaitDisappear(element: cell)

		search.disableWholeWord()
		awaitAppear(element: cell)
		
		search.enableWholeWord()
		awaitDisappear(element: cell)
	}
	
	func testSearchIsUpdated() {
		let brokers = Brokers(app: app)
		
		let hostname = TestServer.getTestServer()
		let alias = "Example"
		let id = Navigation.id()
		
		let examples = ExampleMessages(broker: Broker(alias: nil, hostname: hostname))
		app.launch()
		
		brokers.start(alias: alias)
		examples.publish(prefix: id)
		
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "\(id)hue/light/office")

		let search = Search(app: app)
		search.searchFor(text: "On")

		let center = nav.groupCell(topic: "\(id)hue/light/office/center")
		let left = nav.groupCell(topic: "\(id)hue/light/office/left")
		let right = nav.groupCell(topic: "\(id)hue/light/office/right")
		awaitAppear(element: center)
		awaitAppear(element: left)
		awaitAppear(element: right)
		
		examples.publish("\(id)hue/light/office/left",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":230}")
		examples.publish("\(id)hue/light/office/center",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":233}")
		examples.publish("\(id)hue/light/office/right",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":230}")

		awaitDisappear(element: center)
		awaitDisappear(element: left)
		awaitDisappear(element: right)
		
		examples.publish(prefix: id)
		
		awaitAppear(element: center)
		awaitAppear(element: left)
		awaitAppear(element: right)
	}
}
