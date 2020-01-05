//
//  QuickFilterTextObservable.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI
import Combine

class QuickFilterTextDebounce {
	var filterText = "" {
		willSet {
			DispatchQueue.main.async {
				self.searchSubject.send(newValue)
			}
		}
	}

	let searchSubject = PassthroughSubject<String, Never>()
	
	private var filterCancellable: Cancellable? {
		didSet {
			oldValue?.cancel()
		}
	}
	
	deinit {
		filterCancellable?.cancel()
	}
	
	init() {
		filterCancellable = searchSubject.eraseToAnyPublisher()
		.map { $0 }
		.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
		.removeDuplicates()
		.receive(on: DispatchQueue.main)
		.sink(receiveValue: { (searchText) in
			self.onChange(text: searchText)
		})
	}
	
	func onChange(text: String) {
	}
}
