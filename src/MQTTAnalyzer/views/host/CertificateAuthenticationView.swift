//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI

struct CertificateAuthenticationView: View {
	@Binding var host: HostFormModel

	@State var serverCA: String = ""
	@State var clientCertificate: String = ""
	@State var clientKey: String = ""
	@State var clientKeyPassword: String = ""
	
	var body: some View {
		Group {
			List {
				CertificateFileItemView(name: "Server CA", filename: $host.certServerCA)
				CertificateFileItemView(name: "Client Certificate", filename: $host.certClient)
				CertificateFileItemView(name: "Client Key", filename: $host.certClientKey)
			}
			
			HStack {
				Text("Password")
					.font(.headline)
				
					Spacer()
				
				SecureField("optional key file password", text: $host.certClientKeyPassword)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

struct CertificateFileItemView: View {
	let name: String
	@Binding var filename: String
	
	var body: some View {
		NavigationLink(destination: CertificateFilePickerView(fileName: $filename)) {
			HStack {
				Text(name)
				.font(.headline)
				
				Spacer()
				
				Text(filename.isBlank ? "select" : filename)
			}
		}
	}
}
