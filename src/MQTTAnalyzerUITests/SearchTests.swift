//
//  MQTTAnalyzerUITests+Broker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-12.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

class SearchTests: AbstractUITests {
	func testSearch() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "home")
		
		let cell = nav.groupCell(topic: "home/dishwasher/000123456789")
		awaitDisappear(element: cell)
		
		let search = Search(app: app)
		search.searchFor(text: "running")
		
		awaitAppear(element: cell)
	}
	
	func testToggleWholeWord() {
		let brokers = Brokers(app: app)
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "home")
		
		let cell = nav.groupCell(topic: "home/dishwasher/000123456789")
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
		
		let hostname = "localhost"
		let alias = "Example"

		let examples = ExampleMessages(hostname: hostname)
		app.launch()
		examples.publish()
		brokers.start(alias: alias)
		let nav = Navigation(app: app, alias: alias)
		nav.navigate(to: "hue/light/office")

		let search = Search(app: app)
		search.searchFor(text: "On")

		let center = nav.groupCell(topic: "hue/light/office/center")
		let left = nav.groupCell(topic: "hue/light/office/left")
		let right = nav.groupCell(topic: "hue/light/office/right")
		awaitAppear(element: center)
		awaitAppear(element: left)
		awaitAppear(element: right)
		
		examples.publish("hue/light/office/left",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":230}")
		examples.publish("hue/light/office/center",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":233}")
		examples.publish("hue/light/office/right",
				"{\"state\":\"OFF\",\"brightness\":100,\"color_temp\":230}")

		awaitDisappear(element: center)
		awaitDisappear(element: left)
		awaitDisappear(element: right)
		
		examples.publish()
		
		awaitAppear(element: center)
		awaitAppear(element: left)
		awaitAppear(element: right)
	}
}
