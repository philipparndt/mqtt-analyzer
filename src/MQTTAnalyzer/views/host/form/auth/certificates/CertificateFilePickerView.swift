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
	@ObservedObject var fileLister = FileLister()
		
	var body: some View {
		Group {
			List {
				if CloudDataManager.sharedInstance.isCloudEnabled() {
					CertificateLocationSectionView(type: Binding(
					get: {
						return self.fileLister.certificateLocation
					},
					set: { (newValue) in
						return self.fileLister.certificateLocation = newValue
					}))
				}
				
				FileListView(refreshHandler: fileLister.refresh,
							 type: self.type,
							 files: fileLister.files,
							 file: $file,
							 certificateLocation: Binding(
				get: {
					return self.fileLister.certificateLocation
				},
				set: { (newValue) in
					return self.fileLister.certificateLocation = newValue
				}))
	
				PKCS12HelpView()
			}
		}
		.navigationBarTitle("Select \(type.getName())")
	}
}
