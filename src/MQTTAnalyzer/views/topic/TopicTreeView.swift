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

	var body: some View {
		List(selection: $selectedTopic) {
			if model.childrenDisplay.isEmpty && model.children.isEmpty {
				ContentUnavailableView(
					"No Topics",
					systemImage: "antenna.radiowaves.left.and.right",
					description: Text(host.state == .connected ? "Waiting for messages..." : "Connect to receive messages.")
				)
			} else {
				OutlineGroup(
					model.childrenDisplay.sorted { $0.name < $1.name },
					children: \.treeChildren
				) { node in
					TreeNodeCellView(model: node, host: host)
						.tag(node)
				}
			}
		}
		.listStyle(.sidebar)
		.scrollContentBackground(.hidden)
		.background(.ultraThinMaterial)
		.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
		.toolbarBackgroundVisibility(.visible, for: .navigationBar)
		.navigationTitle(host.settings.aliasOrHost)
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				ControlGroup {
					Button(action: model.markRead) {
						Label("Mark read", systemImage: "circlebadge")
					}

					Button(role: .destructive, action: model.clear) {
						Label("Clear", systemImage: "trash")
					}
				}
			}

			ToolbarItem(placement: .secondaryAction) {
				Button(action: togglePause) {
					Label(host.pause ? "Resume" : "Pause", systemImage: host.pause ? "play.fill" : "pause.fill")
				}
			}
		}
		.safeAreaInset(edge: .bottom) {
			connectionStatusView
		}
		.onAppear {
			if !host.needsAuth && host.state == .disconnected {
				rootModel.connect(to: host)
			}
		}
	}

	func togglePause() {
		host.pause.toggle()
	}

	@ViewBuilder
	var connectionStatusView: some View {
		VStack(spacing: 0) {
			if host.state == .connecting {
				ConnectingView(host: host)
			} else if host.state == .disconnected {
				if host.reconnectDelegate != nil {
					DisconnectedView(host: host)
				} else {
					Button("Connect") {
						rootModel.connect(to: host)
					}
					.buttonStyle(.borderedProminent)
					.padding()
				}
			} else if host.pause {
				ResumeConnectionView(host: host)
			}
		}
		.background(.ultraThinMaterial)
	}
}

// MARK: - Tree Navigation View (replaces FolderNavigationView)
/// Use this inside an existing List - it returns a Section with OutlineGroup
struct TreeNavigationView: View {
	@ObservedObject var host: Host
	@ObservedObject var model: TopicTree

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
						TreeNodeCellView(model: node, host: host)
					}
					.accessibilityLabel("topic: \(node.nameQualified)")
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

	var body: some View {
		HStack {
			FolderReadMarkerView(read: model.readState)

			Text(model.name.isBlank ? "<empty>" : model.name)
				.foregroundColor(model.name.isBlank ? .gray : .primary)

			Spacer()

			// Message count badge
			if !model.messages.isEmpty {
				Text("\(model.messages.count)")
					.font(.caption2)
					.padding(.horizontal, 5)
					.padding(.vertical, 2)
					.background(Color.accentColor.opacity(0.15))
					.cornerRadius(6)
			}

			CounterCellView(model: model)
		}
		.contextMenu {
			MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
			MenuButton(title: "Copy name", systemImage: "doc.on.doc", action: copyName)

			Menu {
				DestructiveMenuButton(
					title: "Delete retained messages from broker",
					systemImage: "trash.fill",
					action: deleteAllRetained
				)
				.accessibilityLabel("confirm-delete-retained")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityLabel("delete-retained")
		}
	}

	func copyTopic() {
		UIPasteboard.general.string = model.nameQualified
	}

	func copyName() {
		UIPasteboard.general.string = model.name
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
