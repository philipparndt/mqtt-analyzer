//
//  MqttClientSharedUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

class MqttClientSharedUtils {
	func waitFor(predicate: @escaping () -> Bool) -> DispatchTimeoutResult {
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			while !predicate() {
				usleep(useconds_t(500))
			}
			group.leave()
		}

		return group.wait(timeout: .now() + 10)
	}
	
}
