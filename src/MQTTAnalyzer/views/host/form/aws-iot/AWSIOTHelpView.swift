//
//  AWSIoTHelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-20.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct AWSIoTHelpView: View {
	@Binding var host: HostFormModel
	
    var body: some View {
		HStack {
			VStack {
				HStack {
					Text("[AWS IoT documentation](https://github.com/philipparndt/mqtt-analyzer/blob/master/Docs/examples/aws/README.md)")
						.foregroundColor(.blue)
					Spacer()
				}
				
				if host.suggestAWSIOTChanges() {
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
		self.host.updateSettingsForAWSIOT()
	}
}
