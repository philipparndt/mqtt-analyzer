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
	@Binding var clientImpl: HostClientImplType
	
	@State var serverCA: String = ""
	@State var clientCertificate: String = ""
	@State var clientKey: String = ""
	@State var clientKeyPassword: String = ""
	
	var body: some View {
		Group {
			List {
				if clientImpl == .cocoamqtt {
					CertificateFileItemView(name: "Client PKCS12", filename: $host.certClient)
				}
				else {
					CertificateFileItemView(name: "Server CA", filename: $host.certServerCA)
					CertificateFileItemView(name: "Client Certificate", filename: $host.certClient)
					CertificateFileItemView(name: "Client Key", filename: $host.certClientKey)
				}
			}
			
			HStack {
				Text("Password")
					.font(.headline)
				
					Spacer()
				
				SecureField(clientImpl == .cocoamqtt ? "password" : "optional key file password", text: $host.certClientKeyPassword)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
			
			InfoBox(text: "Certificate files are not synced. "
				+ "Copy them to all of your devices using Finder / iTunes.")
		}
	}
}

struct CertificateFileItemView: View {
	let name: String
	@Binding var filename: String
	
	var body: some View {
		NavigationLink(destination: CertificateFilePickerView(type: name, fileName: $filename)) {
			HStack {
				Text(name)
				.font(.headline)
				
				Spacer()
				
				Group {
					if filename.isBlank {
						Text("select")
							.foregroundColor(.gray)
					}
					else {
						Text(filename)
					}
				}.font(.body)
			}
		}
	}
}
