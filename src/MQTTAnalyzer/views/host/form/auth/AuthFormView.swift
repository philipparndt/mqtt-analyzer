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
			AuthenticationTypePicker(type: $host.authType)
			
			if self.host.authType == .usernamePassword {
				UsernamePasswordAuthenticationView(host: $host)
			}
			else if self.host.authType == .certificate {
				CertificateAuthenticationView(host: $host, clientImpl: $host.clientImpl)
			}
		}
	}
}
