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
	@Binding var type: HostAuthenticationType
	
	var body: some View {
		return Section(header: Text("Authentication")) {
			AuthenticationTypePicker(type: $type)
			
			if self.type == .usernamePassword {
				UsernamePasswordAuthenticationView(host: $host)
			}
			else if self.type == .certificate {
				CertificateAuthenticationView(host: $host)
			}
		}
	}
}
