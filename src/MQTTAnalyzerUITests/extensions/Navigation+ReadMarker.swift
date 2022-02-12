//
//  ReadMarker.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 2022-02-09.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import XCTest

extension Navigation {
	func getReadMarker(topic: String) -> XCUIElement {
		return folderCell(topic: topic)
			.images["Circle"]
	}
	
	func getReadMarker(of element: XCUIElement) -> XCUIElement {
		return element.images["Circle"]
	}
}
