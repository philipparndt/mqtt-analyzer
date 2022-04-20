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
	
	var body: some View {
		Group {
			List {
				CertificateFileItemView(type: .p12, file: $host.certP12)
			}
			
			HStack {
				Text("Password")
					.font(.headline)
				
					Spacer()
				
				SecureField("password", text: $host.certClientKeyPassword)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

struct CertificateFileItemView: View {
	let type: CertificateFileType
	@Binding var file: CertificateFile?
	
	var body: some View {
		NavigationLink(destination: CertificateFilePickerView(type: type,
															  file: $file,
															  location: getSelectedLocation())) {
			HStack {
				Text("\(type.getName())")
				.font(.headline)
				
				Spacer()
				
				Group {
					if !isSelected() {
						Text("select")
							.foregroundColor(.gray)
					}
					else {
						Text(getFilename())
					}
				}.font(.body)
			}
		}
	}
	
	func getSelectedLocation() -> CertificateLocation {
		return file?.location ?? .local
	}
	
	func isSelected() -> Bool {
		return file != nil
	}
	
	func getFilename() -> String {
		return file?.name ?? ""
	}
}
