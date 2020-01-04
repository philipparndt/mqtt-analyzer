//
//  JSonStringExtension.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import Highlightr

class JsonFormatString {
	var attributedMessage: NSAttributedString?
	let json: String
	
	init(json: String) {
		self.json = json
	}
	
	func getAttributed() -> NSAttributedString {
		let result = self.attributedMessage ?? highlightText(json: json)
		self.attributedMessage = result
		return result
	}
	
	private func highlightText(json message: String) -> NSAttributedString {
		let highlightr = Highlightr()!
		highlightr.setTheme(to: UITraitCollection.current.userInterfaceStyle == .light ? "paraiso-light" : "paraiso-dark")
		return highlightr.highlight(message, as: "json")!
	}
}
