//
//  MigrationHelper.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

func hasProperties(_ oldObject: DynamicObject?, properties: String...) -> Bool {
	for property in properties {
		if !(oldObject?.objectSchema
		.properties
			.contains(where: { $0.name == property }) ?? false) {
			return false
		}
	}
	
	return true
}
