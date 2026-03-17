//
//  AuthFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct AuthFormView: View {
	@Binding var host: HostFormModel
	@Binding var showCertificateHelp: Bool

	var body: some View {
		Section(header: Text("Authentication"), footer: authFooter) {
			Toggle(isOn: $host.usernamePasswordAuth) {
				VStack(alignment: .leading, spacing: 2) {
					Text("Username/Password")
						.font(.headline)
					Text("Authenticate with credentials")
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.accessibilityIdentifier("userPassword-auth")

			if host.usernamePasswordAuth {
				UsernamePasswordAuthenticationView(host: $host)
			}

			Toggle(isOn: $host.certificateAuth) {
				VStack(alignment: .leading, spacing: 2) {
					Text("Client Certificate (mTLS)")
						.font(.headline)
					Text("Authenticate with a client certificate")
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.accessibilityIdentifier("certificate-auth")

			if host.certificateAuth {
				CertificateAuthenticationView(host: $host, showHelp: $showCertificateHelp)
			}
		}
	}

	@ViewBuilder
	private var authFooter: some View {
		if !host.usernamePasswordAuth && !host.certificateAuth {
			Text("Configure how to authenticate with the broker.")
				.font(.caption)
		} else {
			EmptyView()
		}
	}
}
