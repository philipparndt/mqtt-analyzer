//
//  AWSIoTHelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-20.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ClientCertsHelpView: View {
	@Binding var host: HostFormModel
	
    var body: some View {
		HStack {
			VStack {
				HStack {
					Text("[Client certificates documentation](https://github.com/philipparndt/mqtt-analyzer/blob/master/Docs/examples/client-certs/README.md)")
						.foregroundColor(.blue)
					Spacer()
				}
				
				if host.suggestClientCertsTLSChanges() {
					Text("") // Space
					HStack {
						Button(action: self.updateSettings) {
							Text("Apply default values")
						}
						Spacer()
					}
				}
			}
			
			Spacer()
			
			Image(systemName: "questionmark.circle.fill")
		}
		.padding()
		.font(.body)
		.background(Color.green.opacity(0.1))
		.cornerRadius(10)
    }
	
	func updateSettings() {
		self.host.updateSettingsForClientCertsTLS()
	}
}
