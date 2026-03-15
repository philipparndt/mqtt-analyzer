//
//  LoginDialog.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-09.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct LoginData {
	var username: String = ""
	var password: String = ""
	var isPresented = false
}

struct LoginDialogView: View {
	let loginCallback: () -> Void

	@ObservedObject var host: Host
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		LoginFormView(
			username: host.settings.username ?? "",
			password: host.settings.password ?? "",
			onLogin: login,
			onCancel: { dismiss() }
		)
	}

	func login(username: String, password: String) {
		host.usernameNonpersistent = username
		host.passwordNonpersistent = password
		loginCallback()
	}
}

struct LoginFormView: View {
	@State var username: String
	@State var password: String
	let onLogin: (String, String) -> Void
	let onCancel: () -> Void

	@FocusState private var focusedField: Field?

	private enum Field {
		case username, password
	}

	var body: some View {
		VStack(spacing: 0) {
			// Header
			VStack(spacing: 8) {
				Image(systemName: "lock.shield")
					.font(.system(size: 40))
					.foregroundColor(.accentColor)

				Text("Authentication Required")
					.font(.headline)

				Text("Enter your credentials to connect")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			.padding(.top, 24)
			.padding(.bottom, 20)

			// Fields
			VStack(spacing: 12) {
				VStack(alignment: .leading, spacing: 4) {
					Text("Username")
						.font(.caption)
						.foregroundColor(.secondary)

					TextField("", text: $username)
						.textFieldStyle(.roundedBorder)
						.disableAutocorrection(true)
						#if os(iOS)
						.textInputAutocapitalization(.never)
						#endif
						.focused($focusedField, equals: .username)
						.onSubmit { focusedField = .password }
						.accessibilityLabel("Username")
				}

				VStack(alignment: .leading, spacing: 4) {
					Text("Password")
						.font(.caption)
						.foregroundColor(.secondary)

					SecureField("", text: $password)
						.textFieldStyle(.roundedBorder)
						.disableAutocorrection(true)
						#if os(iOS)
						.textInputAutocapitalization(.never)
						#endif
						.focused($focusedField, equals: .password)
						.onSubmit { login() }
						.accessibilityLabel("Password")
				}
			}
			.padding(.horizontal, 24)

			Spacer()
				.frame(height: 24)

			// Buttons
			VStack(spacing: 10) {
				Button(action: login) {
					Text("Login")
						.fontWeight(.semibold)
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)

				Button("Cancel", action: onCancel)
					.buttonStyle(.borderless)
					.foregroundColor(.secondary)
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 24)
		}
		#if os(macOS)
		.frame(width: 320, height: 340)
		#else
		.frame(maxWidth: 360)
		#endif
		.onAppear {
			focusedField = username.isEmpty ? .username : .password
		}
	}

	private func login() {
		onLogin(username, password)
	}
}
