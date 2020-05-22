//
//  File.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

struct CertificateFile: Identifiable, Comparable {
	let name: String
	let id = UUID.init()
	let location: CertificateLocation
	
	static func < (lhs: CertificateFile, rhs: CertificateFile) -> Bool {
		return lhs.name < rhs.name
    }
}
