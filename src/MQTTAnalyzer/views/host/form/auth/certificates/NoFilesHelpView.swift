//
//  NoFilesHelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct NoFilesHelpView: View {
	@Binding var certificateLocation: CertificateLocation
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("No certificate files here yet.")
				.font(.headline)
			
			Spacer()
			
			if certificateLocation == .cloud {
				Text("Add new *.p12 / *.pfx or *.crt and *.key files to iCloud drive (MQTTAnalyzer folder)")
				Spacer()
				Text("Use local files when you prefer them due to security reasons.")
			}
			else {
				Text("Add new *.p12 / *.pfx or *.crt and *.key files with Finder or iTunes.")
				Spacer()
				Text("Use the iCloud drive when you like to sync your certificates between your devices.")
			}
		}.foregroundColor(.secondary)
	}
}
