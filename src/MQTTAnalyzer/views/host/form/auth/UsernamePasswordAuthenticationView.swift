//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI

struct UsernamePasswordAuthenticationView: View {
	@Binding var host: HostFormModel

	var body: some View {
		Group {
			HStack {
				Text("Username")
					.font(.headline)

				Spacer()

				TextField("username", text: $host.username)
					.disableAutocorrection(true)
					#if !os(macOS)
					.textInputAutocapitalization(.never)
					#endif
					.multilineTextAlignment(.trailing)
					.font(.body)
					.accessibilityLabel("your username")
			}

			HStack {
				Text("Password")
					.font(.headline)

				Spacer()

				SecureField("your password", text: $host.password)
					.disableAutocorrection(true)
					#if !os(macOS)
					.textInputAutocapitalization(.never)
					#endif
					.multilineTextAlignment(.trailing)
					.font(.body)
					.accessibilityLabel("password")
			}

			HStack(alignment: .top, spacing: 6) {
				Image(systemName: "info.circle")
					.foregroundColor(.blue)
					.font(.caption)
				Text("Leave username and/or password empty to avoid storing them. You will be prompted to enter credentials when connecting.")
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
	}
}
