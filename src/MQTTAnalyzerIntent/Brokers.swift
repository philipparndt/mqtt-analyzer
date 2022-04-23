//
//  Brokers.swift
//  MQTTAnalyzerIntent
//
//  Created by Philipp Arndt on 22.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

func loadBrokers() -> [NSString] {
	let sqlite = SQLitePersistence()
	let brokers = sqlite.allNames()
	sqlite.close()
	
	return brokers
		.map { $0 as NSString }
}

func firstBroker(by name: String) -> Host? {
	let sqlite = SQLitePersistence()
	let broker = sqlite.first(by: name)
	sqlite.close()
	return broker
}
