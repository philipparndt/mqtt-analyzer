//
//  File.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

struct CertificateFileModel: Identifiable, Comparable, Hashable {
	let name: String
	let location: CertificateLocation

	/// Stable ID based on name and location to ensure SwiftUI list identity is preserved
	var id: String {
		"\(location.rawValue):\(name)"
	}

	static func < (lhs: CertificateFileModel, rhs: CertificateFileModel) -> Bool {
		return lhs.name < rhs.name
	}

	static func == (lhs: CertificateFileModel, rhs: CertificateFileModel) -> Bool {
		return lhs.name == rhs.name && lhs.location == rhs.location
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(location)
	}
}
