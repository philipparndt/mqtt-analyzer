//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct AuthenticationTypeSectionView: View {
	@Binding var type: HostAuthenticationType

	var body: some View {
		Section(header: Text("Authentication type")) {
			AuthenticationTypePicker(type: $type)
		}
	}
}

struct AuthenticationTypePicker: View {
	@Binding var type: HostAuthenticationType

	var body: some View {
		Picker(selection: $type, label: Text("Auth")) {
			Text("None").tag(HostAuthenticationType.none)
			Text("User/password").tag(HostAuthenticationType.usernamePassword)
			Text("Certificate").tag(HostAuthenticationType.certificate)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
