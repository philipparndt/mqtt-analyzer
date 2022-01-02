//
//  ImportCertificatePicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-26.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI
import CoreServices
import UniformTypeIdentifiers

struct ImportCertificatePickerView: View {
	var refreshHandler: CertificateFilesRefresh
	@State var shows = false
	
	var body: some View {
		Button(action: self.toggle) {
			HStack {
				Image(systemName: "icloud.and.arrow.down.fill")
				Text("Import from iCloud...")
			}
		}
		.sheet(isPresented: self.$shows) {
			DocumentPickerView(refresh: self.refreshHandler,
							   documentTypes: [UTType.pkcs12.identifier, UTType.x509Certificate.identifier])
		}
	}
	
	func toggle() {
		self.shows.toggle()
	}
}
