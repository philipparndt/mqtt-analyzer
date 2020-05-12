//
//  NamedLink.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-12.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

struct NamedLink: Identifiable {
	let id = UUID()
	let name: String
	let link: String
}
