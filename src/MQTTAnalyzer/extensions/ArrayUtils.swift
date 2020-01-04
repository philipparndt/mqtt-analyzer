//
//  ArrayUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

extension Array {
	mutating func remove(atOffsets offsets: IndexSet) {
		let suffixStart = halfStablePartition { index, _ in
			return offsets.contains(index)
		}
		removeSubrange(suffixStart...)
	}

	mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
		let suffixStart = halfStablePartition { index, _ in
			return source.contains(index)
		}
		let suffix = self[suffixStart...]
		removeSubrange(suffixStart...)
		insert(contentsOf: suffix, at: destination)
	}

	mutating func halfStablePartition(isSuffixElement predicate: (Index, Element) -> Bool) -> Index {
		guard var i = firstIndex(where: predicate) else {
			return endIndex
		}

		var j = index(after: i)
		while j != endIndex {
			if !predicate(j, self[j]) {
				swapAt(i, j)
				formIndex(after: &i)
			}
			formIndex(after: &j)
		}
		return i
	}

	func firstIndex(where predicate: (Index, Element) -> Bool) -> Index? {
		for (index, element) in self.enumerated() {
			if predicate(index, element) {
				return index
			}
		}
		return nil
	}
}
