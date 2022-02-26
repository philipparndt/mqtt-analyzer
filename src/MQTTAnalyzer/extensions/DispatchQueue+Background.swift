//
//  DispatchQueue+Background.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-26.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//
// see https://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift

import Foundation

extension DispatchQueue {

	static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
		DispatchQueue.global(qos: .background).async {
			background?()
			if let completion = completion {
				DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
					completion()
				})
			}
		}
	}

}
