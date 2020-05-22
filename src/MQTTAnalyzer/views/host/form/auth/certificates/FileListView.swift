//
//  FileListView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct FileListView: View {
	var refreshHandler: () -> Void
	let type: CertificateFileType
	var files: [CertificateFileModel]
	@Binding var file: CertificateFile?
	@Binding var certificateLocation: CertificateLocation
	
	var body: some View {
		Section(header: Text("Files")) {
			if files.isEmpty {
				NoFilesHelpView(certificateLocation: $certificateLocation)
				.foregroundColor(.secondary)
			}
			
			ForEach(files) { file in
				FileItemView(fileName: file, type: self.type, selection: self.$file).font(.body)
			}
			
			Button(action: refreshHandler) {
				HStack {
					Image(systemName: "arrow.2.circlepath")
					Text("Refresh")
				}
			}.font(.body)
		}
	}
}
