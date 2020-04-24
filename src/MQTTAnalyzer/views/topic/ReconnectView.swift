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
	
	@Binding
	var loginDialogPresented: Bool
	
	var foregroundColor: Color {
		if host.state == .connected {
			if host.pause {
				return .white
			}
			else if model.topicLimit || model.messageLimit {
				return .black
			}
			
			return !host.pause ? .gray : .white
		}
		else {
			return .white
		}
	}
	
	var backgroundColor: Color {
		if host.state == .connected {
			if host.pause {
				return .gray
			}
			else if model.topicLimit || model.messageLimit {
				return .yellow
			}
			
			return .green
		}
		else if host.state == .connecting {
			return .gray
		}
		else {
			return .red
		}
	}

	var body: some View {
		Group {
			if host.needsAuth {
				Button(action: authenticate) {
					FillingText(text: "Authentication required!",
					imageName: "exclamationmark.octagon.fill")
				}
			}
			else if model.topicLimit && !host.pause {
				HStack {
					FillingText(text: "Topic limit exceeded.\nReduce the subscription topic!",
					imageName: "exclamationmark.octagon.fill")
				}
			}
			else if model.messageLimit && !host.pause {
				HStack {
					FillingText(text: "Message limit exceeded.\nReduce the subscription topic!",
					imageName: "exclamationmark.octagon.fill")
				}
			}
			else if host.state == .connected {
				if host.pause {
					Button(action: pause) {
						FillingText(text: "Connected (paused)")
					}
				}
			}
			else if host.state == .connecting {
				if host.connectionMessage != nil {
					HStack {
						FillingText(text: host.connectionMessage ?? "Connecting...")
					}
				}
			} else if host.state == .disconnected {
				Button(action: reconnect) {
					FillingText(text: host.connectionMessage ?? "Disconnected",
								imageName: "xmark.octagon.fill")
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
	
	func authenticate() {
		loginDialogPresented = true
	}
}
