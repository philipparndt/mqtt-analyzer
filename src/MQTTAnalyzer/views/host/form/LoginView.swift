//
//  LoginView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct LoginView: View {
	@Binding
	var loginDialogPresented: Bool

	var host: Host
	
	var body: some View {
		HStack {
			Text("Authentication required!")

			Spacer()

			Button(action: authenticate) {
				HStack {
					Image(systemName: "exclamationmark.octagon.fill")
					
					Text("Authenticate")
				}
			}
			.accessibilityLabel("Play")
		}
		.padding()
	}

	func authenticate() {
		loginDialogPresented = true
	}
}
