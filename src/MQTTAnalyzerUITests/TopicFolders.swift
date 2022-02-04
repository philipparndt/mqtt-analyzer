//
//  BrokerForm.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import XCTest

class TopicFolders {
	let app: XCUIApplication
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func navigate(to topic: String) {
		let split = topic.split(separator: "/")
		for i in 0 ..< split.count {
			open(topic: split[0...i].joined(separator: "/"))
		}
	}
	
	func open(topic: String) {
		app.cells["folder: \(topic)"].tap()
	}
}
