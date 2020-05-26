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
	var refreshDelegate: () -> Void
	
    class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
		var refreshDelegate: () -> Void
        var parent: DocumentPickerView

		init(_ parent: DocumentPickerView, refreshDelegate: @escaping () -> Void) {
            self.parent = parent
			self.refreshDelegate = refreshDelegate
        }
		
		func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			for url in urls {
				CloudDataManager.sharedInstance.copyFileToLocal(file: url)
			}
			
			self.refreshDelegate()
		}
    }
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self, refreshDelegate: self.refreshDelegate)
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPickerView>) -> UIDocumentPickerViewController {
		let picker = UIDocumentPickerViewController(
			documentTypes: ["public.item"], in: .import)
		
		picker.shouldShowFileExtensions = true
		picker.delegate = context.coordinator
		
		return picker
	}

	func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {

	}
}
