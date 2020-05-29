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
	@ObservedObject var model: CertificateFilesModel
	@Binding var file: CertificateFile?
	@Binding var certificateLocation: CertificateLocation
	
	var body: some View {
		Section(header: Text("Files")) {
			if model.getFiles(of: certificateLocation).isEmpty {
				NoFilesHelpView(certificateLocation: $certificateLocation)
				.foregroundColor(.secondary)
			}
			
			ForEach(model.getFiles(of: certificateLocation)) { file in
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
		let deleted = self.model.delete(at: offsets, on: self.certificateLocation)
		
		for toBeDeleted in deleted {
			if toBeDeleted.name == self.file?.name && toBeDeleted.location == self.file?.location {
				self.file = nil
			}
		}
	}
}
