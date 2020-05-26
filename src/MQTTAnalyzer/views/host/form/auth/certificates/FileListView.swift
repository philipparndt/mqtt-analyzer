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
			.onDelete(perform: self.delete)
			
			Button(action: refreshHandler) {
				HStack {
					Image(systemName: "arrow.2.circlepath")
					Text("Refresh")
				}
			}.font(.body)
		}
	}
	
	func delete(at offsets: IndexSet) {
		DispatchQueue.global(qos: .userInitiated).async {
			
			offsets.forEach {
				let toBeDeleted = self.files[$0]
				if toBeDeleted.name == self.file?.name && toBeDeleted.location == self.file?.location {
					self.file = nil
				}
				
				CloudDataManager.sharedInstance.deleteLocalFile(fileName: self.files[$0].name)
			}
			
//			self.files.remove(atOffsets: offsets)
		}
	}
}
