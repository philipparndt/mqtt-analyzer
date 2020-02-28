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
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
			
			HStack {
				Text("Password")
					.font(.headline)
				
					Spacer()
				
				SecureField("password", text: $host.password)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
			
			InfoBox(text: "Leave username and/or password empty. In order to not persist them. You will get a login dialog.")
		}
	}
}
