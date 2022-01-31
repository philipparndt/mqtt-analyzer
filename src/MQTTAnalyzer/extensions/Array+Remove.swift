//
//  Array+Remove.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-31.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension Array {
	mutating func remove(atOffsets offsets: IndexSet) {
		let suffixStart = halfStablePartition { index, _ in
			return offsets.contains(index)
		}
		removeSubrange(suffixStart...)
	}
}
