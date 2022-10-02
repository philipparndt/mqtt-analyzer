//
//  Persistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-06.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

protocol Persistence {
	func delete(_ host: Host)
	
	func load()
	
	func create(_ host: Host)
		
	func update(_ host: Host)
}
