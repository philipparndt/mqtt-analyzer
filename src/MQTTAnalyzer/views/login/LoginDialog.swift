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
	@Binding var data: LoginData

	var body: some View {
		NavigationView {
			LoginFormView(data: self.$data, loginCallback: login)
				.font(.caption)
				.navigationBarTitle(Text("Login"))
				.keyboardResponsive()
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func login() {
		host.usernameNonpersistent = data.username
		host.passwordNonpersistent = data.password
		loginCallback()
	}
	
}

struct LoginFormView: View {
	@Binding var data: LoginData
	let loginCallback: () -> Void
	
	var body: some View {
		Group {
			Form {
				Section {
					HStack {
						Text("Username")
							.font(.headline)
						
						Spacer()
					
						TextField("username", text: $data.username)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.multilineTextAlignment(.trailing)
							.font(.body)
					}
					
					HStack {
						Text("Password")
							.font(.headline)
						
							Spacer()
						
						SecureField("password", text: $data.password)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.multilineTextAlignment(.trailing)
							.font(.body)
					}
				}
				
				Section {
					Button(action: loginCallback) {
						Text("Login")
						.padding()
						.font(.headline)
							.frame(minWidth: 250, maxWidth: .infinity, alignment: .center)
						.foregroundColor(.white)
						.background(Color.blue)
						.cornerRadius(15)
					}
				}
			}
		}
	}
}
