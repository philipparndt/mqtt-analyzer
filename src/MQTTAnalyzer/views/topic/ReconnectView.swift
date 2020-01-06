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
	var imageName: String?
	
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
	
	@ObservedObject
	var model: MessageModel
	
	var foregroundColor: Color {
		if host.connected {
			if model.topicLimit || model.messageLimit {
				return .black
			}
			
			return host.connected && !host.pause ? .gray : .white
		}
		else {
			return .white
		}
	}
	
	var backgroundColor: Color {
		if host.connected {
			if model.topicLimit || model.messageLimit {
				return .yellow
			}
			
			return .green
		}
		else if host.connecting {
			return .gray
		}
		else {
			return .red
		}
	}
	
	var body: some View {
		Group {
			if model.topicLimit {
				HStack {
					FillingText(text: "Topic limit exceeded.\nReduce the subscription topic!",
					imageName: "exclamationmark.octagon.fill")
				}
			}
			else if model.messageLimit {
				HStack {
					FillingText(text: "Message limit exceeded.\nReduce the subscription topic!",
					imageName: "exclamationmark.octagon.fill")
				}
			}
			else if host.connected {
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
