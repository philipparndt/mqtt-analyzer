//
//  ResumeConnectionView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2021-06-14.
//  Copyright © 2021 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ResumeConnectionView: View {
	var host: Host
	
	var body: some View {
		HStack {
			Text("Connection paused")

			Spacer()

			Button(action: resumeConnection) {
				HStack {
					Image(systemName: "play.fill")
					
					Text("Resume")
				}
			}
		}
		.padding()
	}
	
	func resumeConnection() {
		host.pause=false
	}
}
