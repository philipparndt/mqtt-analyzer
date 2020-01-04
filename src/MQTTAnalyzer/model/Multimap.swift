//
//  Multimap.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-04.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class Multimap<K: Hashable, V> {
	var dict: [K: [V]] = [:]
	
	func put(key: K, value: V) {
		if var existingValues = self.dict[key] {
			existingValues.append(value)
			self.dict[key] = existingValues
		} else {
			self.dict[key] = [value]
		}
	}
}
