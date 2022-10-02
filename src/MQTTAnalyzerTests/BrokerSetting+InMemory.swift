//
//  BrokerSetting+InMemory.swift
//  MQTTAnalyzerTests
//
//  Created by Philipp Arndt on 17.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//
@testable import MQTTAnalyzer
import Foundation

extension BrokerSetting {
	class func stub() -> BrokerSetting {
		return BrokerSetting(context: PersistenceController(inMemory: true).container.viewContext)
	}
}
