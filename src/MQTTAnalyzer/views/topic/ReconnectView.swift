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
    
	var foregroundColor: Color {
		host.connected && !host.pause ? .gray : .white
	}
	
	var backgroundColor: Color {
		host.connected ? host.pause ? .gray : Color.green.opacity(0.3) : host.connecting ? .gray : .red
	}
	
    var body: some View {
        Group {
			if host.connecting {
				HStack {
					Text("Connecting...")
					
					Spacer()
				}
			} else if !host.connected {
				Button(action: reconnect) {
					VStack {
						HStack {
							Text(host.connectionMessage ?? "Disconnected")
							
							Spacer()
							
							Image(systemName: "desktopcomputer")
						}
					}
				}
			}
			else {
				Button(action: pause) {
					HStack {
						Text(host.pause ? "Connected (paused)" : "Connected")
						
						Spacer()

						Image(systemName: host.pause ? "play.fill" : "pause.fill")
					}
				}
			}
		}
		.padding([.leading, .trailing])
		.padding([.bottom, .top], 10)
		.foregroundColor(foregroundColor)
		.background(backgroundColor)
    }
    
	func pause() {
		self.host.pause.toggle()
    }
	
    func reconnect() {
        self.host.reconnect()
    }
}
