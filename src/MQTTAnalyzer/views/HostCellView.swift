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
	
	mutating func present(type: HostCellViewSheetType) {
		self.type = type
		self.isPresented = true
	}
}

struct HostCellView: View {
	@Environment(\.managedObjectContext) private var viewContext

	@EnvironmentObject var model: RootModel
	@ObservedObject var host: Host
	@ObservedObject var hostsModel: HostsModel
	@ObservedObject var messageModel: TopicTree
	
	@State private var sheetState = ServerPageSheetState()
	
	@State private var loginData = LoginData()
	
	var cloneHostHandler: (Host) -> Void
	
	var connectionColor: Color {
		host.state == .connected ? .green : .gray
	}
	
	var body: some View {
		NavigationLink(destination: TopicsView(model: messageModel, host: host)) {
			HStack {
				VStack(alignment: .leading) {
					Text(host.settings.aliasOrHost)

					Spacer()
					Group {
						Text(host.settings.hostname)
						Text(host.subscriptionsReadable)
					}
					.font(.footnote)
					.foregroundColor(.secondary)
				}
				
				Spacer()

				if host.state != .disconnected {
					Text("\(messageModel.messageCountDisplay)")
						.font(.system(size: 14, design: .monospaced))
						.foregroundColor(.secondary)

					Image(systemName: host.pause ? "pause.fill" : "circle.fill" )
						.font(.subheadline)
						.foregroundColor(host.pause ? .gray : connectionColor)
				}

				contextMenu()
			}.padding([.top, .bottom], 5)
		}
		.sheet(isPresented: $sheetState.isPresented, onDismiss: cancelEditCreation, content: {
			if self.sheetState.type == .edit {
				EditHostFormModalView(closeHandler: self.cancelEditCreation,
									  root: self.model,
									  hosts: self.model.hostsModel,
									  original: self.host.settings,
									  host: transformHost(source: self.host))
			}
			else {
				LoginDialogView(loginCallback: self.login, host: self.host)
			}
		})
		.onAppear {
			if self.host.needsAuth {
				self.loginData.username = self.host.settings.username ?? ""
				self.loginData.password = self.host.settings.password ?? ""
			}
		}
	}

	func contextMenu() -> some View {
		return Text("").contextMenu {
			MenuButton(title: "Edit", systemImage: "pencil.circle", action: editHost)
			MenuButton(title: "Create new based on this", systemImage: "pencil.circle", action: cloneHost)
			if host.state != .disconnected {
				Menu {
					MenuButton(title: "Disconnect", systemImage: "stop.circle", action: disconnect)
					
					DestructiveMenuButton(title: "Disconnect and clean", systemImage: "stop.circle", action: disconnectClean)
				} label: {
					Label("Disconnect", systemImage: "stop.circle")
				}
			}
			else {
				MenuButton(title: "Connect", systemImage: "play.circle", action: connect)
			}
			
			Divider()
		
			Menu {
				DestructiveMenuButton(title: "Delete broker", systemImage: "trash.fill", action: deleteBroker)
					.accessibilityLabel("confirm-delete-broker")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityLabel("delete-broker")
		}
		// WORKAROUND: random UUID identifier to force re-creation of the context menu.
		// Otherwise, it will not toggle between connect and disconnect.
//		.id(UUID().uuidString)
	}
	
	func cloneHost() {
		cloneHostHandler(host)
	}
	
	func editHost() {
		sheetState.present(type: .edit)
	}
	
	func deleteBroker() {
		let broker = host.settings
		viewContext.delete(broker)
		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
}
	
	func disconnect() {
		host.disconnect()
	}
	
	func disconnectClean() {
		host.disconnect()
		messageModel.clear()
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
		sheetState.isPresented = false
		model.connect(to: self.host)
	}
	
	func cancelEditCreation() {
		sheetState.isPresented = false
	}
}
