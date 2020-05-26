//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI
import Combine

struct CertificateFilePickerView: View {
	let type: CertificateFileType
	
	@Binding var file: CertificateFile?
	@ObservedObject var fileLister: FileLister
	@State var location: CertificateLocation
	
	var body: some View {
		Group {
			List {
				Section(header: Text("Location")) {
					if CloudDataManager.sharedInstance.isCloudEnabled() {
						CertificateLocationPicker(type: Binding(
						get: {
							return self.location
						},
						set: { (newValue) in
							self.location = newValue
							self.refresh()
						}))
					}
					
					if location == .local {
						ImportCertificatePickerView(refreshDelegate: refresh)
					}
				}
				
				FileListView(refreshHandler: refresh,
							 type: self.type,
							 files: fileLister.files,
							 file: $file,
							 certificateLocation: $location)
	
				PKCS12HelpView()
			}
		}
		.navigationBarTitle("Select \(type.getName())")
	}
	
	private func refresh() {
		fileLister.refresh(on: location)
	}
}
