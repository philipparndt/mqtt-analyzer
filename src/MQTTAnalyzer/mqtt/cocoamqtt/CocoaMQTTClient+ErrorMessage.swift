//
//  CocoaMQTTClient+ErrorMessage.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 08.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

extension MqttClientCocoaMQTT {
	class func extractErrorMessage(error: Error) -> String {
		let nsError = error as NSError
		let code = nsError.code
		
		if code == 8 {
			return "Invalid hostname.\n\(error.localizedDescription)"
		}
		else if nsError.domain == "Network.NWError" {
			if nsError.description.starts(with: "-9808") {
				return "Bad certificate format, check all properties, like SAN, ... (-9808)"
			}
			else {
				let groups = nsError.description.groups(for: ".*\\(rawValue:.(\\d+)\\):.(.*)")
				if groups.count == 1 && groups[0].count == 3 {
					return "\(groups[0][2]) (NW: \(groups[0][1]))"
				}
			}
		}
		
		return "\(nsError.domain): \(nsError.description)"
	}
}
