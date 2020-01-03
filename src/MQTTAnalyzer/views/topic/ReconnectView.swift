//
//  ReconnectView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ReconnectView: View {
    
    @ObservedObject
    var host: Host
    
    var body: some View {
        Group {
			Section(header: Text("Connection")) {
				if host.connecting {
					HStack {
					   Text("Connecting...")
					}.foregroundColor(.gray)
				} else if !host.connected {
						HStack {
							Image(systemName: "desktopcomputer")
											   .padding()

							Button(action: reconnect) {
								Text("Disconnected")
							}
		
							if host.connectionMessage != nil {
								HStack {
									Text(host.connectionMessage!)
								}.foregroundColor(.gray)
							}
						}.foregroundColor(.red)
				}
				else {
					HStack {
						Text(host.pause ? "Connected (paused)" : "Connected")
						
						Spacer()
						
						Button(action: pause) {
							Image(systemName: host.pause ? "play.fill" : "pause.fill")
						}
					}.foregroundColor(.gray)
				}
			}
        }
    }
    
	func pause() {
		self.host.pause.toggle()
    }
	
    func reconnect() {
        self.host.reconnect()
    }
}
