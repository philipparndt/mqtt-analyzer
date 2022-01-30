//
//  Readstate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

class Readstate: ObservableObject {
	@Published var read: Bool = false

	func markRead() {
		read = true
	}
	
	func markUnread() {
		read = false
	}
}
