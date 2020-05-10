//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI

struct FileItemView: View {
	let fileName: String
	@Binding var selection: String
	
	var body: some View {
		HStack {
			Image(systemName: self.selection == fileName ? "largecircle.fill.circle" : "circle")
				.foregroundColor(.blue)
			
			Image(systemName: "doc.text.fill")
				.foregroundColor(.secondary)
			
			Text(fileName)
			
			Spacer()
		}
		.onTapGesture {
			self.selection = self.fileName
		}
	}
}

struct File: Identifiable, Comparable {
	let name: String
	let id = UUID.init()
	
	static func < (lhs: File, rhs: File) -> Bool {
		return lhs.name < rhs.name
    }
}

struct CertificateFilePickerView: View {

	let type: String
	
	@Binding var fileName: String
	
	var body: some View {
		Group {
			Spacer()
			
			InfoBox(text: "Add new *.p12 / *.pfx or *.crt and *.key files with Finder or iTunes.\n\n"
			 + "Create p12 file using:\n`openssl pkcs12 -export -in user.crt -inkey user.key -out user.p12`")
			.padding(.horizontal)
			
			List {
				ForEach(listFiles()) { file in
					FileItemView(fileName: file.name, selection: self.$fileName).font(.body)
				}
			}
		}
		.navigationBarTitle("Select \(type)")
	}
	
	func listFiles() -> [File] {
		let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		do {
			let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
			
			let files = directoryContents
				.map { $0.lastPathComponent }
				.filter { $0.lowercased().range(of: #".*\.(p12|pfx|crt|key)"#, options: .regularExpression) != nil}
				.map { File(name: $0) }
				.sorted()

			return files
		} catch {
			return [File(name: error.localizedDescription)]
		}
	}
}
