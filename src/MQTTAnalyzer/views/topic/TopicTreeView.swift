//
//  TopicTreeView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-04.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: - Tree Children Extension
extension TopicTree {
	/// Returns sorted children as optional array for SwiftUI tree views
	/// Returns nil when empty (required for OutlineGroup/List leaf detection)
	var treeChildren: [TopicTree]? {
		let sorted = children.values.sorted { $0.name < $1.name }
		return sorted.isEmpty ? nil : sorted
	}
}

// MARK: - Hashable conformance for List selection
extension TopicTree: Hashable {
	static func == (lhs: TopicTree, rhs: TopicTree) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

// MARK: - Topic Tree Sidebar (for three-column layout on macOS/iPad)
struct TopicTreeSidebarView: View {
	@EnvironmentObject var rootModel: RootModel
	@ObservedObject var host: Host
	@ObservedObject var model: TopicTree
	@Binding var selectedTopic: TopicTree?

	@StateObject private var publishMessageModel = PublishMessageFormModel()
	@State private var limitsSettingsPresented = false
	@State private var limitsSettingsType: LimitType = .topicLimit

	var isSearching: Bool {
		!model.filterText.trimmingCharacters(in: .whitespaces).isEmpty
	}

	var body: some View {
		#if os(macOS)
		VStack(spacing: 0) {
			topicList
			connectionStatusView
		}
		#else
		topicList
			.safeAreaInset(edge: .bottom) {
				connectionStatusView
			}
			.onAppear {
				if !host.needsAuth && host.state == .disconnected {
					rootModel.connect(to: host)
				}
			}
		#endif
	}

	private var topicList: some View {
		List(selection: $selectedTopic) {
			if isSearching {
				// Show search results
				if model.searchResultDisplay.isEmpty {
					ContentUnavailableView(
						"No Results",
						systemImage: "magnifyingglass",
						description: Text("No topics match '\(model.filterText)'")
					)
				} else {
					ForEach(model.searchResultDisplay) { node in
						TreeNodeCellView(
							model: node,
							host: host,
							publishMessagePresented: $publishMessageModel.isPresented,
							selectMessage: selectMessage,
							createNewTopic: setTopic,
							showFullPath: true
						)
						.tag(node)
					}
				}
			} else if model.childrenDisplay.isEmpty && model.children.isEmpty {
				ContentUnavailableView(
					"No Topics",
					systemImage: "antenna.radiowaves.left.and.right",
					description: Text(host.state == .connected ? "Waiting for messages..." : "Connect to receive messages.")
				)
				.accessibilityIdentifier(host.state == .connected ? "tree_wait_messages" : "tree_not_connected")
			} else {
				OutlineGroup(
					model.childrenDisplay.sorted { $0.name < $1.name },
					children: \.treeChildren
				) { node in
					TreeNodeCellView(
						model: node,
						host: host,
						publishMessagePresented: $publishMessageModel.isPresented,
						selectMessage: selectMessage,
						createNewTopic: setTopic
					)
						.tag(node)
				}
				.animation(nil, value: model.childrenDisplay.count)
			}
		}
		.listStyle(.sidebar)
		.searchable(text: $model.filterText)
		.disableAutocorrection(true)
		.transaction { transaction in
			transaction.animation = nil
		}
		#if os(iOS)
		.scrollContentBackground(.hidden)
		.background(.ultraThinMaterial)
		.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
		.toolbarBackgroundVisibility(.visible, for: .navigationBar)
		#elseif os(macOS)
		.scrollContentBackground(.hidden)
		.visualEffectBackground(material: .sidebar)
		#endif
		.sheet(isPresented: $publishMessageModel.isPresented, onDismiss: cancelPublishDialog, content: {
			PublishMessageFormModalView(
				closeCallback: self.cancelPublishDialog,
				root: self.rootModel,
				host: self.host,
				model: publishMessageModel
			)
		})
		.sheet(isPresented: $limitsSettingsPresented) {
			LimitsSettingsDialog(
				host: host,
				model: model,
				limitType: limitsSettingsType,
				onDismiss: { limitsSettingsPresented = false }
			)
		}
		.navigationTitle(host.settings.aliasOrHost)
		#if os(macOS)
		.toolbar(removing: .title)
		.toolbar {
			ToolbarItem(placement: .principal) {
				StatisticsPanel(model: model, onPublish: createTopic)
			}

			ToolbarItem(placement: .secondaryAction) {
				if host.state == .disconnected {
					Button(action: { host.reconnect() }) {
						Label("Connect", systemImage: "play.fill")
					}
				} else {
					Button(action: togglePause) {
						Label(host.pause ? "Resume" : "Pause", systemImage: host.pause ? "play.fill" : "pause.fill")
					}
				}
			}
		}
		#else
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button(action: createTopic) {
					Label("Publish", systemImage: "paperplane.fill")
				}
				.accessibilityIdentifier("Publish")
			}

			ToolbarItem(placement: .primaryAction) {
				Button(action: model.markRead) {
					Label("Mark read", systemImage: "circlebadge")
				}
			}

			ToolbarItem(placement: .primaryAction) {
				Button(role: .destructive, action: model.clear) {
					Label("Clear", systemImage: "trash")
				}
			}

			ToolbarItem(placement: .primaryAction) {
				Button(action: togglePause) {
					Label(host.pause ? "Resume" : "Pause", systemImage: host.pause ? "play.fill" : "pause.fill")
				}
			}
		}
		#endif
	}

	func togglePause() {
		host.pause.toggle()
	}

	func createTopic() {
		publishMessageModel.topic = model.nameQualified
		publishMessageModel.isPresented = true
	}

	func setTopic(_ topic: String) {
		publishMessageModel.topic = topic
	}

	func selectMessage(message: MsgMessage) {
		publishMessageModel.topic = message.topic.nameQualified
		publishMessageModel.message = message.payload.dataString
		publishMessageModel.qos = Int(message.metadata.qos)
		publishMessageModel.retain = message.metadata.retain
		publishMessageModel.messageType = message.payload.isJSON ? .json : .plain

		// Populate JSON form properties if message is JSON
		if let json = message.payload.jsonData {
			publishMessageModel.jsonData = json
			publishMessageModel.properties = createJsonProperties(json: json, path: [])
				.sorted(by: { $0.pathName < $1.pathName })
		} else {
			publishMessageModel.jsonData = nil
			publishMessageModel.properties = []
		}

		publishMessageModel.isPresented = true
	}

	func cancelPublishDialog() {
		publishMessageModel.isPresented = false
	}

	@ViewBuilder
	var connectionStatusView: some View {
		if model.rootTopicLimitExceeded && !host.pause {
			TopicLimitReachedView(
				onDismiss: dismissLimitWarning,
				onOpenSettings: { openLimitsSettings(type: .topicLimit) }
			)
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
			.padding(.horizontal, 8)
			.padding(.bottom, 8)
		} else if model.rootMessageLimitExceeded && !host.pause {
			MessageLimitReachedView(
				onDismiss: dismissLimitWarning,
				onOpenSettings: { openLimitsSettings(type: .messageBatchLimit) }
			)
			.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
			.padding(.horizontal, 8)
			.padding(.bottom, 8)
		} else if host.state == .connecting {
			ConnectionStatusBanner(
				message: host.connectionMessage ?? "Connecting...",
				icon: "antenna.radiowaves.left.and.right",
				color: Color.blue,
				action: { },
				host: host
			)
		} else if host.state == .disconnected && host.reconnectDelegate != nil {
			ConnectionStatusBanner(
				message: host.connectionMessage ?? "Disconnected",
				icon: "exclamationmark.triangle.fill",
				color: .orange,
				action: { host.reconnect() },
				host: host
			)
		}
	}

	func dismissLimitWarning() {
		let root = model.findRoot()
		root.topicLimitExceeded = false
		root.messageLimitExceeded = false
	}

	func openLimitsSettings(type: LimitType) {
		limitsSettingsType = type
		limitsSettingsPresented = true
	}
}

// MARK: - Modern Connection Status Banner
struct ConnectionStatusBanner: View {
	let message: String
	let icon: String
	let color: Color
	let action: (() -> Void)?
	var host: Host?
	@State private var showDiagnostics = false

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: icon)
				.foregroundStyle(color)

			Text(message)
				.font(.callout)
				.lineLimit(1)

			Spacer()

			if host?.state == .disconnected, host?.connectionMessage != nil, let host {
				Button {
					showDiagnostics = true
				} label: {
					Image(systemName: "stethoscope")
						.font(.callout)
						.foregroundStyle(.orange)
				}
				.buttonStyle(.plain)
				.sheet(isPresented: $showDiagnostics) {
					DiagnosticsView(host: host, isPresented: $showDiagnostics, connectionError: host.connectionMessage)
				}
			}

			if let action = action {
				Button(action: action) {
					Image(systemName: "arrow.clockwise.circle.fill")
						.font(.title2)
						.foregroundStyle(color)
				}
				.buttonStyle(.plain)
			} else {
				ProgressView()
					.controlSize(.small)
			}
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.padding(.horizontal, 8)
		.padding(.bottom, 8)
	}
}

// MARK: - Tree Navigation View (replaces FolderNavigationView)
/// Use this inside an existing List - it returns a Section with OutlineGroup
struct TreeNavigationView: View {
	@ObservedObject var host: Host
	@ObservedObject var model: TopicTree
	var publishMessagePresented: Binding<Bool>?
	var selectMessage: ((MsgMessage) -> Void)?
	var createNewTopic: ((String) -> Void)?

	var emptyTopicText: String {
		if model.filterText.isEmpty {
			return "no topics available"
		} else {
			return "no topics available using the current filter"
		}
	}

	var body: some View {
		Section(header: Text("Topics")) {
			if model.childrenDisplay.isEmpty {
				Text(emptyTopicText)
					.foregroundColor(.secondary)
			} else {
				OutlineGroup(
					model.childrenDisplay.sorted { $0.name < $1.name },
					children: \.treeChildren
				) { node in
					NavigationLink(destination: TopicsView(model: node, host: host)) {
						TreeNodeCellView(
							model: node,
							host: host,
							publishMessagePresented: publishMessagePresented,
							selectMessage: selectMessage,
							createNewTopic: createNewTopic
						)
					}
					.accessibilityIdentifier("folder: \(node.nameQualified)")
				}
			}
		}
	}
}

// MARK: - Tree Node Cell View
struct TreeNodeCellView: View {
	@ObservedObject var model: TopicTree
	@EnvironmentObject var root: RootModel
	let host: Host
	var publishMessagePresented: Binding<Bool>?
	var selectMessage: ((MsgMessage) -> Void)?
	var createNewTopic: ((String) -> Void)?
	var showFullPath: Bool = false

	var displayName: String {
		if showFullPath {
			return model.nameQualified.isEmpty ? "<empty>" : model.nameQualified
		} else {
			return model.name.isBlank ? "<empty>" : model.name
		}
	}

	var body: some View {
		HStack {
			FolderReadMarkerView(read: model.readState)

			Text(displayName)
				.foregroundColor(model.name.isBlank ? .gray : .primary)

			Spacer()

			CounterCellView(model: model)
		}
		.contextMenu {
			MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
			MenuButton(title: "Copy name", systemImage: "doc.on.doc", action: copyName)

			if createNewTopic != nil {
				Menu {
					if !model.messages.isEmpty {
						MenuButton(title: "Message again", systemImage: "paperplane.fill", action: publish)
					}
					MenuButton(title: "New message", systemImage: "paperplane.fill", action: publishNew)
						.accessibilityIdentifier("publish new")
				} label: {
					Label("Publish", systemImage: "paperplane.fill")
				}
				.accessibilityIdentifier("publish")
			}

			Menu {
				DestructiveMenuButton(
					title: "Delete retained messages from broker",
					systemImage: "trash.fill",
					action: deleteAllRetained
				)
				.accessibilityIdentifier("confirm-delete-retained")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityIdentifier("delete-retained")
		}
		.accessibilityIdentifier("folder: \(model.nameQualified)")
	}

	func copyTopic() {
		Pasteboard.copy(model.nameQualified)
	}

	func copyName() {
		Pasteboard.copy(model.name)
	}

	func publish() {
		if let first = model.messages.last {
			root.publish(message: first, on: host)
		}
	}

	func publishNew() {
		// Use the last message as a template if available
		if let first = model.messages.last {
			selectMessage?(first)
		} else {
			createNewTopic?(model.nameQualified)
			publishMessagePresented?.wrappedValue = true
		}
	}

	func deleteAllRetained() {
		model.pauseAcceptEmptyFor(seconds: 5)

		let messages = model.allRetainedMessages
		for message in messages {
			root.publish(
				message: MsgMessage(
					topic: message.topic,
					payload: MsgPayload(data: []),
					metadata: MsgMetadata(qos: message.metadata.qos, retain: true)
				),
				on: host
			)
		}

		for message in messages {
			message.topic.delete(message: message)
		}
	}
}
