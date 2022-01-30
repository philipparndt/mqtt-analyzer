//
//  TopicTreeFilterExt.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-30.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension TopicTree {
	func updateChildrenToDisplay() {
		return childrenDisplay = Array(children.values
			.filter { $0.matches(filter: filterTextCleaned) }
			.sorted { $0.name < $1.name }
		)
	}
	
	func matches(filter: String) -> Bool {
		if filter.isEmpty {
			return true
		}
		
		if nameQualified.lowercased().contains(filter) {
			return true
		}
		
		for child in children.values {
			if child.matches(filter: filter) {
				return true
			}
		}
		
		return false
	}
}
