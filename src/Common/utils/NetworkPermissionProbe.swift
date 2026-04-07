//
//  NetworkPermissionProbe.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-04-04.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Triggers the macOS network permission dialog on app startup by making a
/// lightweight TCP connection probe. This ensures the user is prompted to allow
/// network access before they attempt their first MQTT connection.
enum NetworkPermissionProbe {
	/// Starts a brief outbound TCP connection to trigger the OS network permission dialog.
	/// The connection is cancelled immediately after being established or failing.
	static func trigger() {
		#if os(macOS)
		let connection = NWConnection(
			host: NWEndpoint.Host("apple.com"),
			port: 443,
			using: .tcp
		)

		connection.stateUpdateHandler = { state in
			switch state {
			case .ready, .failed, .cancelled:
				connection.cancel()
			default:
				break
			}
		}

		connection.start(queue: DispatchQueue(label: "network-permission-probe"))
		#endif
	}
}
