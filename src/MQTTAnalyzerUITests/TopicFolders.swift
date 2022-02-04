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
	var currentFolder: [String] = []
	
	init(app: XCUIApplication) {
		self.app = app
	}
	
	func navigate(to topic: String) {
		let split = topic.split(separator: "/").map { String($0) }
		if !split.starts(with: currentFolder) {
			XCTFail("Cannot navigate upwards")
		}
		
		for i in currentFolder.count ..< split.count {
			open(topic: split[0...i].joined(separator: "/"))
		}
		
		currentFolder = split
	}
	
	private func open(topic: String) {
		app.cells["folder: \(topic)"].tap()
	}
	
	func flatView() {
		app.switches["flatview"].tap()
	}
	
	func publishNew(topic: String) {
		app.cells["group: \(topic)"].press(forDuration: 1)
		snapshot("2 Context Menu")
		
		app.buttons["publish new"].tap()
		app.buttons["set"].tap()
		snapshot("3 Publish")
		
		app.buttons["Publish"].tap()
	}
}
