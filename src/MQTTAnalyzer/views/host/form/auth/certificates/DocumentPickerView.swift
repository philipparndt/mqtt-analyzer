//
//  DocumentPickerView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-26.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct DocumentPickerView: UIViewControllerRepresentable {
	var refresh: CertificateFilesRefresh
	let documentTypes: [String]
	
    class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
		var refresh: CertificateFilesRefresh
        var parent: DocumentPickerView

		init(_ parent: DocumentPickerView, refresh: CertificateFilesRefresh) {
            self.parent = parent
			self.refresh = refresh
        }
		
		func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			for url in urls {
				CloudDataManager.instance.copyFileToLocal(file: url)
			}
			
			self.refresh.refresh()
		}
    }
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self, refresh: self.refresh)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPickerView>) -> UIDocumentPickerViewController {
		let picker = UIDocumentPickerViewController(
			documentTypes: self.documentTypes, in: .import)

		picker.shouldShowFileExtensions = true
		picker.delegate = context.coordinator
		
		return picker
	}

	func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {

	}
}
