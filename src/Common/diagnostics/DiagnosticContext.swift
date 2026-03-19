//
//  DiagnosticContext.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network

/// Shared context for diagnostic checks containing host information and cached results
class DiagnosticContext {
	/// Hostname to diagnose
	let hostname: String

	/// Port number
	let port: Int

	/// Whether TLS is enabled
	let tlsEnabled: Bool

	/// Whether untrusted certificates are allowed.
	/// Reads from the host settings if available, otherwise uses the stored value.
	var allowUntrusted: Bool {
		host?.settings.untrustedSSL ?? _allowUntrusted
	}
	private var _allowUntrusted: Bool

	/// Reference to the host for certificate access
	weak var host: Host?

	/// Resolved IP addresses (populated by DNS check)
	var resolvedAddresses: [String] = []

	/// Network path status (populated by Reachability check)
	var networkPath: NWPath?

	/// TLS protocol version (populated by TLS Version check)
	var tlsVersion: String?

	/// Server certificate chain (populated by Certificate Chain check)
	var certificateChain: [SecCertificate] = []

	/// Server certificate info (populated by Certificate Chain check)
	var serverCertInfo: CertInfo?

	/// Server certificate data (populated by Certificate Chain check)
	var serverCertData: Data?

	/// Trust evaluation result (populated by Certificate Chain check)
	var trustResult: SecTrustResultType?

	/// Client identity loading issue (populated by DiagnosticTLSHelper)
	var clientIdentityError: String?

	init(hostname: String, port: Int, tlsEnabled: Bool, allowUntrusted: Bool = false, host: Host? = nil) {
		self.hostname = hostname
		self.port = port
		self.tlsEnabled = tlsEnabled
		self._allowUntrusted = allowUntrusted
		self.host = host
	}

	/// Create context from a Host object
	convenience init(host: Host) {
		self.init(
			hostname: host.settings.hostname,
			port: Int(host.settings.port),
			tlsEnabled: host.settings.ssl,
			allowUntrusted: host.settings.untrustedSSL,
			host: host
		)
	}
}
