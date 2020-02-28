//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI

struct RadioItemView: View {
	let fileName: String
	@Binding var selection: String
	
	var body: some View {
		HStack {
			Image(systemName: self.selection == fileName ? "largecircle.fill.circle" : "circle")
				.foregroundColor(.blue)
			
			Text(fileName)
			
			Spacer()
		}
		.onTapGesture {
			self.selection = self.fileName
		}
	}
}

struct CertificateFilePickerView: View {

	@Binding var fileName: String
	
	var body: some View {
		Group {
			InfoBox(text: """
			Connect this device to your computer and drag files to the MQTTAnalyzer App	using Finder (Catalina+) or iTunes.

			You will need distinct files for:
			- Server CA
			- Client Certificate
			- Client Key
			""")
				.padding()
			
			List {
				RadioItemView(fileName: "CA.crt", selection: $fileName)
				RadioItemView(fileName: "client.crt", selection: $fileName)
				RadioItemView(fileName: "client.key", selection: $fileName)
			}
		}
		.navigationBarTitle("Select file")
	}
}
