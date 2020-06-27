//
//  HostCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

enum HostCellViewSheetType {
	case edit
	case login
}

struct ServerPageSheetState {
	var isPresented = false
	var type = HostCellViewSheetType.edit
	
	init() {
		print("init sheet state")
	}
	
	mutating func present(type: HostCellViewSheetType) {
		self.type = type
		self.isPresented = true
	}
}

struct HostCellView: View {
	@EnvironmentObject var model: RootModel
	@ObservedObject var host: Host
	@ObservedObject var messageModel: MessageModel
	
	@Binding var sheetState: ServerPageSheetState
	
	@State private var loginData = LoginData()
	
	var cloneHostHandler: (Host) -> Void
	
	var connectionColor: Color {
		host.state == .connected ? .green : .gray
	}
	
	var body: some View {
		NavigationLink(destination: TopicsView(model: messageModel, host: host)) {
			HStack {
				VStack(alignment: .leading) {
					HStack {
						if host.clientImpl == .moscapsule {
							Image(systemName: "exclamationmark.triangle.fill")
						}
						Text(host.aliasOrHost)
					}
					
					Spacer()
					Group {
						Text(host.hostname)
						Text(host.subscriptionsReadable)
					}
					.font(.footnote)
					.foregroundColor(.secondary)
				}
				
				Spacer()
				
				if host.state != .disconnected {
					Text("\(messageModel.messageCount)")
						.font(.system(size: 14, design: .monospaced))
						.foregroundColor(.secondary)
					
					Image(systemName: "circle.fill")
						.font(.subheadline)
						.foregroundColor(connectionColor)
				}
			}
			.contextMenu {
				MenuButton(title: "Edit", systemImage: "pencil.circle", action: editHost)
				MenuButton(title: "Create new based on this", systemImage: "pencil.circle", action: cloneHost)
				if host.state != .disconnected {
					MenuButton(title: "Disconnect", systemImage: "stop.circle", action: disconnect)
				}
				else {
					MenuButton(title: "Connect", systemImage: "play.circle", action: connect)
				}
			}
		}.sheet(isPresented: $sheetState.isPresented, onDismiss: cancelEditCreation, content: {
			if sheetState.type == .edit {
				EditHostFormModalView(closeHandler: self.cancelEditCreation,
									  root: self.model,
									  hosts: self.model.hostsModel,
									  original: self.host,
									  host: transformHost(source: self.host))
			}
			else {
				LoginDialogView(loginCallback: self.login, host: self.host, data: $loginData)
			}
		})
		.onAppear {
			if host.needsAuth {
				loginData.username = host.username
				loginData.password = host.password
			}
		}
	}
		
	func cloneHost() {
		cloneHostHandler(host)
	}
	
	func editHost() {
		sheetState.present(type: .edit)
	}
	
	func disconnect() {
		host.disconnect()
	}
	
	func connect() {
		if self.host.needsAuth {
			sheetState.present(type: .login)
		}
		else {
			model.connect(to: host)
		}
	}
	
	func login() {
		model.connect(to: self.host)
	}
	
	func cancelEditCreation() {
		sheetState.isPresented = false
	}
}
