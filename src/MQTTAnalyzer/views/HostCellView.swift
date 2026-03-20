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
	@State private var showDiagnostics = false

	@State private var loginData = LoginData()

	var cloneHostHandler: (Host) -> Void
	var isSelected: Bool

	var body: some View {
		HStack(spacing: 12) {
			// Connection status indicator
			statusIndicator

			// Main content
			VStack(alignment: .leading, spacing: 4) {
				// Title row
				HStack(alignment: .firstTextBaseline) {
					Text(host.settings.aliasOrHost)
						.font(.body.weight(.semibold))
						.lineLimit(1)

					Spacer()

					if host.state != .disconnected || messageModel.messageCount > 0 {
						messageCountBadge
					}
				}

				// Host + port info
				HStack(spacing: 6) {
					if host.settings.ssl {
						Image(systemName: "shield.lefthalf.filled")
							.font(.caption2)
					}

					if !host.settings.alias.isEmpty {
						Text(host.settings.hostname)
							.lineLimit(1)
					}

					Text(verbatim: ":\(host.settings.port)")
				}
				.font(.caption)
				.foregroundColor(.secondary)

				// Subscriptions
				Text(host.subscriptionsReadable)
					.font(.caption2)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}

			// Diagnose button for failed connections
			if hasConnectionError {
				Button(action: diagnose) {
					Image(systemName: "stethoscope")
						.font(.title3)
						.foregroundColor(.orange)
				}
				#if os(macOS)
				.buttonStyle(.borderless)
				#else
				.buttonStyle(.plain)
				#endif
				.accessibilityLabel("Diagnose")
			}

			// Action button
			if isSelected || host.state != .disconnected {
				actionButton
			}

			contextMenu()
		}
		.padding(.vertical, 6)
		.contentShape(Rectangle())
		.sheet(item: $activeSheet) { sheetType in
			switch sheetType {
			case .edit:
				EditHostFormModalView(
					closeHandler: self.dismissSheet,
					root: self.model,
					hosts: self.model.hostsModel,
					original: self.host.settings,
					host: transformHost(source: self.host)
				)
			case .login:
				LoginDialogView(loginCallback: self.login, host: self.host)
			}
		}
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(
				host: host,
				isPresented: $showDiagnostics,
				connectionError: host.connectionMessage
			)
		}
		.onAppear {
			if self.host.needsAuth {
				self.loginData.username = self.host.settings.username ?? ""
				self.loginData.password = self.host.settings.password ?? ""
			}
		}
	}

	// MARK: - Status Indicator

	private var statusIndicator: some View {
		RoundedRectangle(cornerRadius: 2)
			.fill(statusColor)
			.frame(width: 4, height: 36)
	}

	private var hasConnectionError: Bool {
		host.state == .disconnected && host.connectionMessage != nil
	}

	private var statusColor: Color {
		if hasConnectionError { return .red }
		switch host.state {
		case .connected:
			return host.pause ? .orange : .green
		case .connecting:
			return .yellow
		case .disconnected:
			return .gray.opacity(0.3)
		}
	}

	// MARK: - Message Count Badge

	private var messageCountBadge: some View {
		Group {
			if host.state == .disconnected && messageModel.messageCount > 0 {
				Button(action: clearMessages) {
					HStack(spacing: 3) {
						Text("\(messageModel.messageCountDisplay)")
						Image(systemName: "xmark")
							.font(.system(size: 8, weight: .bold))
					}
					.font(.caption2.weight(.medium).monospacedDigit())
					.padding(.leading, 6)
					.padding(.trailing, 5)
					.padding(.vertical, 2)
					.background(
						Capsule()
							.fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
					)
					.foregroundColor(isSelected ? .white : .secondary)
				}
				#if os(macOS)
				.buttonStyle(.borderless)
				#else
				.buttonStyle(.plain)
				#endif
				.accessibilityLabel("Clear \(messageModel.messageCount) messages")
			} else {
				Text("\(messageModel.messageCountDisplay)")
					.font(.caption2.weight(.medium).monospacedDigit())
					.padding(.horizontal, 6)
					.padding(.vertical, 2)
					.background(
						Capsule()
							.fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
					)
					.foregroundColor(isSelected ? .white : .secondary)
			}
		}
	}

	// MARK: - Action Button

	private var actionButton: some View {
		Group {
			if host.state == .disconnected {
				Button(action: connect) {
					Image(systemName: "play.circle.fill")
						.font(.title3)
						.foregroundColor(.white)
				}
				.accessibilityLabel("Connect")
			} else {
				Button(action: disconnect) {
					Image(systemName: "stop.circle.fill")
						.font(.title3)
						.foregroundColor(.white)
				}
				.accessibilityLabel("Disconnect")
			}
		}
		#if os(macOS)
		.buttonStyle(.borderless)
		#else
		.buttonStyle(.plain)
		#endif
	}

	// MARK: - Context Menu

	func contextMenu() -> some View {
		return Text("").contextMenu {
			MenuButton(title: "Edit", systemImage: "pencil.circle", action: editHost)
				.accessibilityIdentifier("edit-broker")
			MenuButton(
				title: "Create new based on this",
				systemImage: "pencil.circle",
				action: cloneHost
			)
			if host.state != .disconnected {
				Menu {
					MenuButton(
						title: "Disconnect",
						systemImage: "stop.circle",
						action: disconnect
					)

					DestructiveMenuButton(
						title: "Disconnect and clean",
						systemImage: "stop.circle",
						action: disconnectClean
					)
				} label: {
					Label("Disconnect", systemImage: "stop.circle")
				}
			} else {
				MenuButton(title: "Connect", systemImage: "play.circle", action: connect)
			}

			MenuButton(title: "Diagnose", systemImage: "stethoscope", action: diagnose)

			Divider()

			Menu {
				DestructiveMenuButton(
					title: "Delete broker",
					systemImage: "trash.fill",
					action: deleteBroker
				)
				.accessibilityIdentifier("confirm-delete-broker")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityIdentifier("delete-broker")
		}
	}

	// MARK: - Actions

	func diagnose() {
		showDiagnostics = true
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

	func clearMessages() {
		messageModel.clear()
	}

	func connect() {
		if self.host.needsAuth {
			activeSheet = .login
		} else {
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
