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

	var body: some View {
		NavigationView {
			LoginFormView(username: host.username, password: host.password, loginCallback: login)
				.font(.caption)
				.navigationBarTitle(Text("Login"))
		}
		.navigationViewStyle(StackNavigationViewStyle())
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
	let loginCallback: (String, String) -> Void
	
	var body: some View {
		Group {
			Form {
				Section {
					HStack {
						Text("Username")
							.font(.headline)
						
						Spacer()
					
						TextField("username", text: $username)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.multilineTextAlignment(.trailing)
							.font(.body)
					}
					
					HStack {
						Text("Password")
							.font(.headline)
						
							Spacer()
						
						SecureField("password", text: $password)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.multilineTextAlignment(.trailing)
							.font(.body)
					}
				}
				
				Section {
					Button(action: self.login) {
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
	
	func login() {
		self.loginCallback(self.username, self.password)
	}
}
