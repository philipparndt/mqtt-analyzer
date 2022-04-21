//
//  HostModel+Delete.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension HostsModel {
	func delete(at offsets: IndexSet, persistence: Persistence) {
		let original = hostsSorted
				
		for idx in offsets {
			persistence.delete(original[idx])
		}
		
		persistence.load()
	}
	
	func delete(_ host: Host, persistence: Persistence) {
		persistence.delete(host)
		persistence.load()
	}
}
