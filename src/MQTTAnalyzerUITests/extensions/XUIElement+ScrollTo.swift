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
			swipeUp(velocity: .fast)
		}
	}

	/// Scrolls to make the element visible by swiping within the element's parent scroll view
	/// This is useful on iPad where multiple scroll views may be visible
	func scrollToElementInContainer(element: XCUIElement, container: XCUIElement) {
		while !element.isHittable {
			container.swipeUp(velocity: .fast)
		}
	}

}
