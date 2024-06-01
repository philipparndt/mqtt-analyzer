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

	var body: some View {
		return Section(header: Text("Authentication")) {
			Toggle(isOn: $host.usernamePasswordAuth) {
				Text("Username/password")
					.font(.headline)
					.accessibilityLabel("userPassword-auth")
			}
			if host.usernamePasswordAuth {
				UsernamePasswordAuthenticationView(host: $host)
			}

			Toggle(isOn: $host.certificateAuth) {
				Text("Certificate")
					.font(.headline)
					.accessibilityLabel("certificate-auth")
			}
			if host.certificateAuth {
				CertificateAuthenticationView(host: $host)
			}
		}
	}
}
