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
	let model = CertificateFilesModel.instance
	@State var location: CertificateLocation
	
	var body: some View {
		Group {
			List {
				Section(header: Text("Location")) {
					if CloudDataManager.instance.isCloudEnabled() {
						CertificateLocationPicker(type: Binding(
						get: {
							return self.location
						},
						set: { (newValue) in
							self.location = newValue
							self.model.refresh()
						}))
					}
					
					if location == .local {
						ImportCertificatePickerView(refreshHandler: model)
					}
				}
				
				FileListView(refreshHandler: model.refresh,
							 type: self.type,
							 model: model,
							 file: $file,
							 certificateLocation: $location)
	
				PKCS12HelpView()
			}
		}
		.navigationBarTitle("Select \(type.getName())")
	}
	
}
