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
import Dynamic

struct ImportCertificatePickerView: View {
	var refreshHandler: CertificateFilesRefresh
	@State var shows = false
	
	var body: some View {
		Group {
		#if targetEnvironment(macCatalyst)
			Button(action: self.openFinder) {
				HStack {
					Image(systemName: "folder.fill")
					Text("Show in Finder...")
				}
			}
		#else
			Button(action: self.toggle) {
				HStack {
					Image(systemName: "icloud.and.arrow.down.fill")
					Text("Import from iCloud...")
				}
			}
			.sheet(isPresented: self.$shows) {
				DocumentPickerView(refresh: self.refreshHandler,
								   documentTypes: [UTType.pkcs12, UTType.x509Certificate])
			}
		#endif
		}
		
	}
	
	func openFinder() {
		#if targetEnvironment(macCatalyst)
		
		if let last = CloudDataManager.DocumentsDirectory.localDocumentsURL {
			Dynamic.NSWorkspace.sharedWorkspace.activateFileViewerSelectingURLs([last])
		}
		#endif
	}
	
	func toggle() {
		self.shows.toggle()
	}
}
