//
//  ViewSelection.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-03-27.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class ViewSelection {
	class func update(newValue: String?, setter: @escaping (String?) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			usleep(10_000)
			DispatchQueue.main.async {
				setter(newValue)
			}
		}
	}
}
