//
//  FileItemView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct FileItemView: View {
	let fileName: CertificateFileModel
	let type: CertificateFileType
	@Binding var selection: CertificateFile?
	
	var body: some View {
		HStack {
			Image(systemName: isSelected() ? "largecircle.fill.circle" : "circle")
				.foregroundColor(.blue)
			
			Image(systemName: "doc.text.fill")
				.foregroundColor(.secondary)
			
			Text(fileName.name)
			Spacer()
		}
		.onTapGesture {
			self.selection = CertificateFile(name: self.fileName.name,
											 location: self.fileName.location,
											 type: self.type
			)
		}
	}
	
	func isSelected() -> Bool {
		if let sel = selection {
			return sel.name == fileName.name
				&& sel.location == fileName.location
		}
		
		return false
	}
}
