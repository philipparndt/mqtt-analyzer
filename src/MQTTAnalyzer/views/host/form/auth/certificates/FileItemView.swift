//
//  FileItemView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

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
