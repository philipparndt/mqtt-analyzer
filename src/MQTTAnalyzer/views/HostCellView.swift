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

struct ConfirmDeleteBroker {
	var isPresented = false
	var broker: BrokerSetting?
}

struct HostCellView: View {
	@Environment(\.managedObjectContext) private var viewContext

	@EnvironmentObject var model: RootModel
	@ObservedObject var host: Host
	@ObservedObject var hostsModel: HostsModel
	@ObservedObject var messageModel: TopicTree
	
	@State private var sheetState = ServerPageSheetState()
	
	@State private var confirmDelete = ConfirmDeleteBroker()
	
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

					Image(systemName: "circle.fill")
						.font(.subheadline)
						.foregroundColor(connectionColor)
				}

				contextMenu()
			}.padding([.top, .bottom], 5)
		}
		.confirmationDialog("Are you shure you want to delete the broker setting?", isPresented: $confirmDelete.isPresented, actions: {
			Button("Delete", role: .destructive) {
				deleteBroker()
			}
		})
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
				MenuButton(title: "Disconnect", systemImage: "stop.circle", action: disconnect)
			}
			else {
				MenuButton(title: "Connect", systemImage: "play.circle", action: connect)
			}
			
			Divider()
			DestructiveMenuButton(title: "Delete broker", systemImage: "trash.fill", action: confirmDeleteBroker)
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
	
	func confirmDeleteBroker() {
		confirmDelete.broker = host.settings
		confirmDelete.isPresented = true
	}
	
	func deleteBroker() {
		if let broker = confirmDelete.broker {
			viewContext.delete(broker)
			do {
				try viewContext.save()
			} catch {
				let nsError = error as NSError
				NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
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
		sheetState.isPresented = false
		model.connect(to: self.host)
	}
	
	func cancelEditCreation() {
		sheetState.isPresented = false
	}
}
