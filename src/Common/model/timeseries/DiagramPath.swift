//
//  DiagramPath.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

class DiagramPath: Hashable, Identifiable {
	let path: String
	var lastSegment: String {
		if let idx = path.lastIndex(of: ".") {
			let start = path.index(after: idx)
			return String(path[start...])
		}
		return path
	}
	
	var parentPath: String {
		return path.pathUp(".")
	}
	
	var hasSubpath: Bool {
		return path.contains(".")
	}
	
	init(_ path: String) {
		self.path = path
	}
	
	static func == (lhs: DiagramPath, rhs: DiagramPath) -> Bool {
		return lhs.path == rhs.path
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(path)
	}
}
