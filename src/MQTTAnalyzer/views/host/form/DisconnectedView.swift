//
//  DisconnectedView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DisconnectedView: View {
	var host: Host

	var body: some View {
		HStack {
			Text(host.connectionMessage ?? "Disconnected")
			
			Spacer()
			
			Button(action: reconnect) {
				HStack {
					Image(systemName: "play.fill")
					
					Text("Reconnect")
				}
			}
		}
		.padding()
    }
	
	func reconnect() {
		host.reconnect()
	}
}
