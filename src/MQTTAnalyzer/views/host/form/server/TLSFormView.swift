//
//  TLSFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct TLSFormView: View {
	@Binding var host: HostFormModel

	var body: some View {
		Section(header: Text("TLS"), footer: tlsFooter) {
			Toggle(isOn: $host.ssl) {
				Text("Enable TLS")
					.font(.headline)
			}.accessibilityLabel("tls")

			if host.ssl {
				Toggle(isOn: $host.untrustedSSL) {
					VStack(alignment: .leading, spacing: 2) {
						Text("Allow untrusted")
							.font(.headline)
						Text("Skip certificate validation (insecure)")
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}

				if host.untrustedSSL {
					HStack(spacing: 4) {
						Image(systemName: "exclamationmark.shield")
							.foregroundColor(.orange)
						Text("Certificate validation disabled - connection may be insecure")
							.font(.caption)
							.foregroundColor(.orange)
					}
				}

				if !host.untrustedSSL {
					VStack(alignment: .leading, spacing: 8) {
						CertificatePickerView(
							label: "Server CA",
							file: $host.certServerCA,
							type: .serverCA
						)

						if host.certServerCA == nil {
							VStack(alignment: .leading, spacing: 4) {
								HStack(spacing: 4) {
									Image(systemName: "checkmark.shield")
										.foregroundColor(.green)
									Text("Using system trusted CAs")
										.font(.caption)
										.foregroundColor(.secondary)
								}
								Text("The server certificate will be validated against the system's trusted certificate authorities. Add a custom CA for self-signed or private CA certificates.")
									.font(.caption)
									.foregroundColor(.secondary)
							}
						} else {
							HStack(spacing: 4) {
								Image(systemName: "shield.lefthalf.filled")
									.foregroundColor(.blue)
								Text("Using custom CA for validation")
									.font(.caption)
									.foregroundColor(.secondary)
							}
						}
					}
				}

				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Text("ALPN")
							.font(.headline)

						Spacer()

						TextField("", text: $host.alpn, prompt: Text("e.g. mqtt").foregroundColor(.secondary))
							.multilineTextAlignment(.trailing)
							.disableAutocorrection(true)
							#if !os(macOS)
							.textInputAutocapitalization(.never)
							#endif
							.accessibilityLabel("alpn")
							.font(.body)
					}

					Text("Application-Layer Protocol Negotiation. Used when sharing port 443 with HTTPS.")
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
		}
	}

	@ViewBuilder
	private var tlsFooter: some View {
		if !host.ssl {
			Text("Enable TLS to encrypt the connection to the broker.")
				.font(.caption)
		} else {
			EmptyView()
		}
	}
}
