//
//  XUIElement+Swipe.swift
//  MQTTAnalyzerUITests
//
//  Created by Philipp Arndt on 31.07.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//
import XCTest

extension XCUIElement {

	func scrollToElement(element: XCUIElement) {
		while !element.isHittable {
			swipeUp(velocity: .slow)
		}
	}

}
