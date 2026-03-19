//
//  DiagnosticTLSHelper.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-18.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import Network
import Security

/// Shared helper for creating NWProtocolTLS.Options with client certificate support
enum DiagnosticTLSHelper {

	/// Creates TLS options configured with client identity and trust settings from the diagnostic context.
	/// Always accepts the TLS connection so diagnostics can inspect certificates and TLS metadata.
	/// Trust evaluation results are reported by individual checks (CertificateChainCheck).
	static func createTLSOptions(context: DiagnosticContext) -> NWProtocolTLS.Options {
		let tlsOptions = NWProtocolTLS.Options()
		let secOptions = tlsOptions.securityProtocolOptions

		sec_protocol_options_set_min_tls_protocol_version(secOptions, .TLSv12)
		sec_protocol_options_set_max_tls_protocol_version(secOptions, .TLSv13)

		// Load client identity for mTLS
		if let identity = loadClientIdentity(context: context) {
			sec_protocol_options_set_local_identity(secOptions, identity)
		}

		// Always accept TLS for diagnostics — individual checks evaluate trust separately
		sec_protocol_options_set_verify_block(secOptions, { _, _, completion in
			completion(true)
		}, DispatchQueue.global())

		return tlsOptions
	}

	/// Load the client SecIdentity from the host's P12 certificate.
	/// Stores the reason for failure in `context.clientIdentityError`.
	private static func loadClientIdentity(context: DiagnosticContext) -> sec_identity_t? {
		guard let host = context.host else { return nil }

		let authType = host.settings.authType
		guard authType == .certificate || authType == .both else { return nil }

		guard let p12Cert = getCertificate(host, type: .p12) else {
			context.clientIdentityError = "No client certificate (P12) configured"
			return nil
		}

		do {
			let url = try p12Cert.getFullPath()

			guard let p12Data = try? Data(contentsOf: url) else {
				context.clientIdentityError = "Client certificate file not found: \(p12Cert.name)"
				return nil
			}

			let password = host.settings.certClientKeyPassword ?? ""
			var optionsDict: [String: Any] = [
				kSecImportExportPassphrase as String: password
			]
			#if os(macOS)
			if #available(macOS 15.0, *) {
				optionsDict[kSecImportToMemoryOnly as String] = true
			}
			#endif

			var items: CFArray?
			let status = SecPKCS12Import(p12Data as CFData, optionsDict as NSDictionary, &items)

			if status == errSecAuthFailed {
				context.clientIdentityError = "Wrong password for client certificate"
				return nil
			}

			guard status == errSecSuccess,
				  let array = items as? [[String: Any]],
				  let first = array.first,
				  let identityRef = first[kSecImportItemIdentity as String] else {
				context.clientIdentityError = "Failed to load client identity from P12 (code: \(status))"
				return nil
			}

			// swiftlint:disable:next force_cast
			let secIdentity = identityRef as! SecIdentity
			return sec_identity_create(secIdentity)
		} catch {
			context.clientIdentityError = "Failed to access client certificate: \(error.localizedDescription)"
			return nil
		}
	}

	/// Load custom server CA certificates from the host configuration
	private static func loadServerCATrust(context: DiagnosticContext) -> [SecCertificate]? {
		guard let host = context.host else { return nil }
		guard host.settings.ssl else { return nil }

		do {
			if let certs = try loadServerCACertificates(host: host), !certs.isEmpty {
				return certs
			}
		} catch {
			NSLog("DiagnosticTLSHelper: Failed to load server CA: \(error)")
		}

		return nil
	}
}
