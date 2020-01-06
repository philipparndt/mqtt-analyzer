//
//  ReconnectView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct FillingText: View {
	let text: String
	var imageName: String? = nil
	
	var body: some View {
		HStack {
			Text(text)
			
			Spacer()
			
			if imageName != nil {
				Image(systemName: imageName!)
			}
		}
	}
}

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
			if host.connected {
				// Do nothing
			}
			else if host.connecting {
				HStack {
					FillingText(text: host.connectionMessage ?? "Connecting...")
				}
			} else if !host.connected {
				Button(action: reconnect) {
					FillingText(text: host.connectionMessage ?? "Disconnected",
								imageName: "xmark.octagon.fill")
				}
			}
			else if host.pause {
				Button(action: pause) {
					FillingText(text: "Connected (paused)",
								imageName: "play.fill")
				}
			}
		}
		.padding([.leading, .trailing])
		.padding([.bottom, .top], 10)
		.foregroundColor(foregroundColor)
		.background(backgroundColor)
	}
	
	func pause() {
		host.pause.toggle()
	}
	
	func reconnect() {
		host.reconnect()
	}
}
