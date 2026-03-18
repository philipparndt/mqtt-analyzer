//
//  DNSResolutionCheck.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Checks if the hostname can be resolved to IP addresses
final class DNSResolutionCheck: BaseDiagnosticCheck, @unchecked Sendable {

	init() {
		super.init(
			checkId: "dns",
			title: "DNS Resolution",
			iconName: "network",
			dependencies: []
		)
	}

	override func run(context: DiagnosticContext) async -> DiagnosticResult {
		let start = startTiming()

		// Check if hostname is already an IP address
		if isIPAddress(context.hostname) {
			context.resolvedAddresses = [context.hostname]
			return .success(
				summary: "Using IP address directly",
				details: "Hostname is an IP address: \(context.hostname)",
				duration: elapsed(since: start)
			)
		}

		// Resolve hostname using CFHost
		do {
			let addresses = try await resolveHostname(context.hostname)
			let duration = elapsed(since: start)

			if addresses.isEmpty {
				return .error(
					summary: "No addresses found",
					message: "DNS lookup returned no results",
					details: "The hostname '\(context.hostname)' could not be resolved to any IP addresses.",
					duration: duration,
					solutions: [
						"Check the hostname spelling",
						"Verify DNS server settings on your device",
						"Try using an IP address instead",
						"Check if the broker is on a private network requiring VPN"
					],
					commands: [
						DiagnosticCommand(label: "DNS Lookup", command: "nslookup \(context.hostname)"),
						DiagnosticCommand(label: "Dig Query", command: "dig \(context.hostname)")
					]
				)
			}

			context.resolvedAddresses = addresses
			let addressList = addresses.joined(separator: ", ")
			return .success(
				summary: "Resolved to \(addresses.first ?? "unknown")",
				details: "\(addresses.count) address\(addresses.count == 1 ? "" : "es") found: \(addressList)",
				duration: duration
			)
		} catch {
			let duration = elapsed(since: start)
			return .error(
				summary: "Resolution failed",
				message: error.localizedDescription,
				details: "Failed to resolve '\(context.hostname)': \(error.localizedDescription)",
				duration: duration,
				solutions: [
					"Check your internet connection",
					"Verify the hostname is correct",
					"Try a different DNS server",
					"Check if you need VPN access"
				],
				commands: [
					DiagnosticCommand(label: "DNS Lookup", command: "nslookup \(context.hostname)"),
					DiagnosticCommand(label: "Check DNS Servers", command: "scutil --dns | head -20")
				]
			)
		}
	}

	private func isIPAddress(_ string: String) -> Bool {
		// Check IPv4
		var sin = sockaddr_in()
		if inet_pton(AF_INET, string, &sin.sin_addr) == 1 {
			return true
		}

		// Check IPv6
		var sin6 = sockaddr_in6()
		if inet_pton(AF_INET6, string, &sin6.sin6_addr) == 1 {
			return true
		}

		return false
	}

	private func resolveHostname(_ hostname: String) async throws -> [String] {
		try await withCheckedThrowingContinuation { continuation in
			let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()

			var error = CFStreamError()
			let started = CFHostStartInfoResolution(host, .addresses, &error)

			guard started else {
				continuation.resume(throwing: NSError(
					domain: "DNSResolution",
					code: Int(error.error),
					userInfo: [NSLocalizedDescriptionKey: "Failed to start DNS resolution"]
				))
				return
			}

			var resolved: DarwinBoolean = false
			guard let addressesData = CFHostGetAddressing(host, &resolved)?.takeUnretainedValue() as? [Data],
				  resolved.boolValue else {
				continuation.resume(throwing: NSError(
					domain: "DNSResolution",
					code: -1,
					userInfo: [NSLocalizedDescriptionKey: "DNS resolution did not complete"]
				))
				return
			}

			var addresses: [String] = []

			for addressData in addressesData {
				addressData.withUnsafeBytes { ptr in
					guard let sockaddr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return }

					if sockaddr.pointee.sa_family == sa_family_t(AF_INET) {
						// IPv4
						var addr = sockaddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
						var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
						if inet_ntop(AF_INET, &addr.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
							addresses.append(String(cString: buffer))
						}
					} else if sockaddr.pointee.sa_family == sa_family_t(AF_INET6) {
						// IPv6
						var addr = sockaddr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
						var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
						if inet_ntop(AF_INET6, &addr.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
							addresses.append(String(cString: buffer))
						}
					}
				}
			}

			continuation.resume(returning: addresses)
		}
	}
}
