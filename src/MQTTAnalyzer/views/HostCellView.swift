//
//  HostCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

enum HostCellViewSheetType: Identifiable {
	case edit
	case login

	var id: String {
		switch self {
		case .edit: return "edit"
		case .login: return "login"
		}
	}
}

struct HostCellView: View {
	@Environment(\.managedObjectContext) private var viewContext

	@EnvironmentObject var model: RootModel
	@ObservedObject var host: Host
	@ObservedObject var hostsModel: HostsModel
	@ObservedObject var messageModel: TopicTree

	@State private var activeSheet: HostCellViewSheetType?

	@State private var loginData = LoginData()

	var cloneHostHandler: (Host) -> Void
	var isSelected: Bool
	
	var connectionColor: Color {
		host.state == .connected ? .green : .gray
	}
	
	var body: some View {
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

			if host.state == .disconnected {
				if isSelected {
					Button {
						connect()
					} label: {
						Image(systemName: "play.circle.fill")
							.font(.title2)
							.foregroundColor(.white)
					}
					#if os(macOS)
					.buttonStyle(.borderless)
					#else
					.buttonStyle(.plain)
					#endif
					.accessibilityLabel("Connect")
				}
			} else {
				Text("\(messageModel.messageCountDisplay)")
					.font(.system(size: 14, design: .monospaced))
					.foregroundColor(isSelected ? .white : .secondary)

				if isSelected {
					Button {
						togglePause()
					} label: {
						Image(systemName: host.pause ? "play.circle.fill" : "pause.circle.fill")
							.font(.title2)
							.foregroundColor(.white)
					}
					#if os(macOS)
					.buttonStyle(.borderless)
					#else
					.buttonStyle(.plain)
					#endif
					.accessibilityLabel(host.pause ? "Resume" : "Pause")
				} else {
					Image(systemName: host.pause ? "pause.fill" : "circle.fill")
						.font(.subheadline)
						.foregroundColor(host.pause ? .gray : connectionColor)
				}
			}

			contextMenu()
		}
		.padding([.top, .bottom], 5)
		.contentShape(Rectangle())
		.sheet(item: $activeSheet) { sheetType in
			switch sheetType {
			case .edit:
				EditHostFormModalView(closeHandler: self.dismissSheet,
									  root: self.model,
									  hosts: self.model.hostsModel,
									  original: self.host.settings,
									  host: transformHost(source: self.host))
			case .login:
				LoginDialogView(loginCallback: self.login, host: self.host)
			}
		}
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
					.accessibilityIdentifier("confirm-delete-broker")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityIdentifier("delete-broker")
		}
		// WORKAROUND: random UUID identifier to force re-creation of the context menu.
		// Otherwise, it will not toggle between connect and disconnect.
//		.id(UUID().uuidString)
	}
	
	func cloneHost() {
		cloneHostHandler(host)
	}
	
	func editHost() {
		activeSheet = .edit
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

	func togglePause() {
		host.pause.toggle()
	}

	func disconnectClean() {
		host.disconnect()
		messageModel.clear()
	}
	
	func connect() {
		if self.host.needsAuth {
			activeSheet = .login
		}
		else {
			model.connect(to: host)
		}
	}
	
	func login() {
		activeSheet = nil
		model.connect(to: self.host)
	}

	func dismissSheet() {
		activeSheet = nil
	}
}
