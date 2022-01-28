//
//  PropertyImageProvider.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-27.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

var imageNames = [
	"battery": "battery.100",
	"brightness": "sun.max",
	"button": "togglepower",
	"connection": "wifi",
	"current": "bolt",
	"date": "calendar",
	"datetime": "calendar",
	"humidity": "humidity",
	"illuminance": "sun.max",
	"last-updated": "clock",
	"light": "lightbulb.fill",
	"power": "bolt",
	"rain": "cloud.rain.fill",
	"remaining": "timer",
	"switch": "togglepower",
	"temperature": "thermometer",
	"time": "clock",
	"timedate": "calendar",
	"timestamp": "clock",
	"voltage": "bolt",
	"wifi": "wifi",
	"wind": "wind"
]

class PropertyImageProvider {
	class func byName(property: String) -> String {
		let lowercase = property.lowercased()
		
		if let result = imageNames[lowercase] {
			return result
		}
		
		let components = property.splitCamelCase()
			.lowercased()
			.components(separatedBy: CharacterSet(charactersIn: "-_[/, "))
		
		for component in components {
			if let result = imageNames[component] {
				imageNames[lowercase] = result // next time faster
				return result
			}
		}

		let result = "chart.bar"
		imageNames[lowercase] = result // next time faster
		return result
	}
}
