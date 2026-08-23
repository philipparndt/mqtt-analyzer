//
//  TopicTreeView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-04.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Combine

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

/// Bookkeeping for revealing the flat list in chunks.
///
/// Held by reference because the reveal continues across run loop turns, and a
/// closure that captures the view value reads state as it was when the closure
/// was made.
final class FlatRowReveal: ObservableObject {
	/// Bumped whenever a new row set supersedes the one being revealed.
	var generation = 0
	var renderedCount = 0
}

// MARK: - Topic Tree Sidebar (for three-column layout on macOS/iPad)
struct TopicTreeSidebarView: View {
	@EnvironmentObject var rootModel: RootModel
	@ObservedObject var host: Host
	@ObservedObject var model: TopicTree
	@Binding var selectedTopic: TopicTree?
	/// Only the scroll follower observes this, so a selection change does not
	/// re-render the list itself.
	var selection: TopicSelection?

	@StateObject private var publishMessageModel = PublishMessageFormModel()
	@State private var limitsSettingsPresented = false
	@State private var limitsSettingsType: LimitType = .topicLimit
	@State private var expandedTopics: Set<UUID> = []
	/// Row set of the flat list, refreshed on a timer. Rebuilding it on every
	/// arriving message batch makes List realize all of its rows again, which
	/// stalls the app; coalescing the bursts keeps the row set stable instead.
	@State private var flatRows: [TopicTree] = []
	@State private var flatRefresh = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
	@StateObject private var reveal = FlatRowReveal()

	/// Rows handed to List at once. Everything beyond this follows a run loop turn
	/// later, so a large row set never blocks the main thread in one go.
	private static let revealChunk = 250

	var isSearching: Bool {
		!model.filterText.trimmingCharacters(in: .whitespaces).isEmpty
	}

	/// Every topic that carries messages, the root included, sorted by full path.
	var flatTopics: [TopicTree] {
		model.recusiveAllMessages
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

	@ViewBuilder
	private func scrollFollower(proxy: ScrollViewProxy) -> some View {
		if let selection = selection {
			SelectionScrollFollower(selection: selection, proxy: proxy)
		}
	}

	private var hasTopics: Bool {
		!(model.childrenDisplay.isEmpty && model.children.isEmpty && model.messages.isEmpty)
	}

	private var topicList: some View {
		ScrollViewReader { proxy in
			listContent
				.background(scrollFollower(proxy: proxy))

		}
	}

	private var listContent: some View {
		List(selection: $selectedTopic) {
			if isSearching {
				searchResultRows
			} else if !hasTopics {
				ContentUnavailableView(
					"No Topics",
					systemImage: "antenna.radiowaves.left.and.right",
					description: Text(host.state == .connected ? "Waiting for messages..." : "Connect to receive messages.")
				)
				.accessibilityIdentifier(host.state == .connected ? "tree_wait_messages" : "tree_not_connected")
			} else if model.flatView {
				flatRowsContent
			} else {
				treeRows
			}
		}
		.listStyle(.sidebar)
		.searchable(text: $model.filterText)
		.onAppear { refreshFlatRows() }
		.onChange(of: model.flatView) { refreshFlatRows() }
		.onChange(of: isSearching) { _, searching in
			// Clearing the filter otherwise diffs the search results against the full
			// topic set, and the resulting batched insert measures every row it adds.
			// Dropping the rows while the search results are on screen means the list
			// is filled into an empty table instead, which is the same cheap path the
			// switch between tree and flat view takes.
			if searching {
				applyFlatRows([])
			} else {
				DispatchQueue.main.async { refreshFlatRows() }
			}
		}
		.onChange(of: model.childrenDisplay.count) { refreshFlatRowsIfShrunk() }
		.onReceive(flatRefresh) { _ in refreshFlatRows() }
		.onKeyPress(.rightArrow) { expandSelection() }
		.onKeyPress(.leftArrow) { collapseSelection() }
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
		.sheet(isPresented: $publishMessageModel.isPresented, content: {
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
				StatisticsPanel(model: model, flatView: $model.flatView, onPublish: createTopic)
			}

			ToolbarItem(placement: .secondaryAction) {
				if host.state == .disconnected {
					Button(
						action: { rootModel.connect(to: host) },
						label: { Label("Connect", systemImage: "play.fill") }
					)
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
				Button(action: toggleFlatView) {
					Label(
						model.flatView ? "Tree view" : "Flat view",
						systemImage: model.flatView ? "list.bullet" : "list.bullet.indent"
					)
				}
				.accessibilityIdentifier("flatview")
			}

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

	@ViewBuilder
	private var searchResultRows: some View {
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
	}

	@ViewBuilder
	private var flatRowsContent: some View {
		if flatRows.isEmpty {
			ContentUnavailableView(
				"No Messages",
				systemImage: "envelope",
				description: Text("No messages received yet.")
			)
			.accessibilityIdentifier("tree_flat_empty")
		} else {
			ForEach(flatRows) { node in
				TreeFlatRow(
					node: node,
					depth: 0,
					hasChildren: false,
					host: host,
					expandedTopics: $expandedTopics,
					selectedTopic: $selectedTopic,
					publishMessagePresented: $publishMessageModel.isPresented,
					selectMessage: selectMessage,
					createNewTopic: setTopic,
					showFullPath: true
				)
			}
		}
	}

	@ViewBuilder
	private var treeRows: some View {
		// The root of the displayed tree is the common prefix of the subscriptions,
		// so it receives messages itself whenever a topic is subscribed exactly
		// (`test`) or a wildcard also matches its own level (`test/#` matches `test`).
		if !model.messages.isEmpty {
			TreeFlatRow(
				node: model,
				depth: 0,
				hasChildren: false,
				host: host,
				expandedTopics: $expandedTopics,
				selectedTopic: $selectedTopic,
				publishMessagePresented: $publishMessageModel.isPresented,
				selectMessage: selectMessage,
				createNewTopic: setTopic,
				showFullPath: true
			)
		}

		ForEach(
			flattenTopicTree(
				roots: model.childrenDisplay,
				expanded: expandedTopics
			)
		) { item in
			TreeFlatRow(
				node: item.node,
				depth: item.depth,
				hasChildren: item.hasChildren,
				host: host,
				expandedTopics: $expandedTopics,
				selectedTopic: $selectedTopic,
				publishMessagePresented: $publishMessageModel.isPresented,
				selectMessage: selectMessage,
				createNewTopic: setTopic
			)
		}
		.animation(nil, value: model.childrenDisplay.count)
	}

}

// MARK: - Actions
extension TopicTreeSidebarView {
	/// Right arrow expands the selected topic, or steps into it when it is already
	/// expanded. The tree is a manually flattened list, so the disclosure handling a
	/// real outline view would do has to be done here.
	func expandSelection() -> KeyPress.Result {
		guard !model.flatView, let node = selectedTopic, let children = node.treeChildren else {
			return .ignored
		}

		if expandedTopics.contains(node.id) {
			selectedTopic = children.first
		} else {
			expandedTopics.insert(node.id)
		}

		return .handled
	}

	/// Left arrow collapses the selected topic, or steps out to its parent.
	func collapseSelection() -> KeyPress.Result {
		guard !model.flatView, let node = selectedTopic else {
			return .ignored
		}

		if node.treeChildren != nil && expandedTopics.contains(node.id) {
			expandedTopics.remove(node.id)
			return .handled
		}

		guard let parent = node.parent, parent !== model || !model.messages.isEmpty else {
			return .ignored
		}

		selectedTopic = parent
		return .handled
	}

	/// Take a fresh snapshot of the flat row set, at most as often as the timer fires.
	func refreshFlatRows() {
		guard model.flatView else {
			return
		}

		guard !isSearching else {
			return
		}

		let current = flatTopics
		guard current.count != reveal.renderedCount
			|| !zip(current, flatRows).allSatisfy({ $0 === $1 }) else {
			return
		}

		applyFlatRows(current)
	}

	/// Removing topics has to show up right away; only additions are coalesced.
	func refreshFlatRowsIfShrunk() {
		guard model.flatView, flatTopics.count < reveal.renderedCount else {
			return
		}

		applyFlatRows(flatTopics)
	}

	/// Hand the rows to List, in chunks when there are many of them.
	///
	/// Clearing the search filter puts the whole topic set back at once, and List
	/// realizes and measures every row it is given before it draws anything. Filling
	/// it a chunk per run loop turn keeps each of those passes short.
	func applyFlatRows(_ target: [TopicTree]) {
		reveal.generation += 1

		guard target.count > reveal.renderedCount + Self.revealChunk else {
			setFlatRows(target)
			return
		}

		revealFlatRows(target, upTo: Self.revealChunk, generation: reveal.generation)
	}

	private func revealFlatRows(_ target: [TopicTree], upTo count: Int, generation: Int) {
		guard reveal.generation == generation else {
			// A newer row set took over while this one was still being revealed
			return
		}

		let next = min(count, target.count)
		setFlatRows(next == target.count ? target : Array(target.prefix(next)))

		guard next < target.count else {
			return
		}

		DispatchQueue.main.async {
			revealFlatRows(target, upTo: next + Self.revealChunk, generation: generation)
		}
	}

	private func setFlatRows(_ rows: [TopicTree]) {
		reveal.renderedCount = rows.count
		flatRows = rows
	}

	func togglePause() {
		host.pause.toggle()
	}

	func toggleFlatView() {
		model.flatView.toggle()
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
		// Don't reset the model in the dismiss path. `reset()` empties
		// `properties`, and even from `.sheet(onDismiss:)` the dismissed
		// sheet's view tree can still receive a Toggle/Switch updateUIView
		// that reads `Binding<Array<PublishMessageProperty>>[i]` against the
		// emptied array, crashing with "Index out of range". Form fields are
		// reseeded on each open by the openers instead.
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

/// Scrolls the list to the selected topic.
///
/// A leaf of its own so that following the selection re-renders this and nothing
/// else: the list holds thousands of rows and rebuilding them for a selection
/// change costs tens of milliseconds.
private struct SelectionScrollFollower: View {
	@ObservedObject var selection: TopicSelection
	let proxy: ScrollViewProxy

	var body: some View {
		Color.clear
			.onChange(of: selection.topic) { _, topic in
				guard let topic = topic else {
					return
				}

				proxy.scrollTo(topic.id)
			}
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

	@ViewBuilder
	func destinationView(for node: TopicTree) -> some View {
		if node.children.isEmpty && !node.messages.isEmpty {
			MessagesView(node: node, host: host)
		} else {
			TopicsView(model: node, host: host)
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
					NavigationLink(destination: destinationView(for: node)) {
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

// MARK: - Tree row (manual flatten)
/// Single row in the manually-flattened topic tree. Each row is a flat List
/// row with its own accessibility identifier so XCUITest can locate it
/// (DisclosureGroup merges its label, hiding the inner identifier).
private struct TreeFlatRow: View {
	@ObservedObject var node: TopicTree
	let depth: Int
	let hasChildren: Bool
	let host: Host
	@Binding var expandedTopics: Set<UUID>
	@Binding var selectedTopic: TopicTree?
	@Binding var publishMessagePresented: Bool
	let selectMessage: (MsgMessage) -> Void
	let createNewTopic: (String) -> Void
	var showFullPath: Bool = false

	private var isExpanded: Bool {
		expandedTopics.contains(node.id)
	}

	private func toggleExpansion() {
		if expandedTopics.contains(node.id) {
			expandedTopics.remove(node.id)
		} else {
			expandedTopics.insert(node.id)
		}
	}

	var body: some View {
		HStack(spacing: 4) {
			if depth > 0 {
				Spacer().frame(width: CGFloat(depth) * 16)
			}
			if hasChildren {
				Button(action: toggleExpansion) {
					Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.secondary)
						.frame(width: 14)
						.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
				.accessibilityIdentifier("chevron: \(node.nameQualified)")
			} else {
				Spacer().frame(width: 14)
			}
			TreeNodeCellView(
				model: node,
				host: host,
				publishMessagePresented: $publishMessagePresented,
				selectMessage: selectMessage,
				createNewTopic: createNewTopic,
				showFullPath: showFullPath
			)
		}
		.tag(node)
		#if os(iOS)
		.padding(.vertical, 8)
		.padding(.horizontal, 12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			selectedTopic == node
				? Color(.tertiarySystemFill)
				: Color.clear,
			in: Capsule()
		)
		.padding(.vertical, -8)
		.padding(.horizontal, -12)
		.foregroundStyle(
			selectedTopic == node ? Color.accentColor : Color.primary
		)
		.listRowBackground(Color.clear)
		.contentShape(Rectangle())
		.onTapGesture {
			selectedTopic = node
			// One-way expand: tap-to-expand only, never collapse, so
			// repeated navigation taps don't toggle state. Use the chevron
			// (or future explicit collapse affordance) to collapse.
			if hasChildren && !isExpanded {
				let id = node.id
				DispatchQueue.main.async {
					expandedTopics.insert(id)
				}
			}
		}
		#endif
	}
}

struct FlatTreeRow: Identifiable {
	let node: TopicTree
	let depth: Int
	let hasChildren: Bool
	var id: UUID { node.id }
}

/// Flatten the tree based on current expansion state. Returns visible nodes
/// in display order with their depth so the row view can indent.
func flattenTopicTree(roots: [TopicTree], expanded: Set<UUID>) -> [FlatTreeRow] {
	var result: [FlatTreeRow] = []
	func visit(_ nodes: [TopicTree], depth: Int) {
		for n in nodes.sorted(by: { $0.name < $1.name }) {
			let hasChildren = n.treeChildren != nil
			result.append(FlatTreeRow(node: n, depth: depth, hasChildren: hasChildren))
			if hasChildren && expanded.contains(n.id), let children = n.treeChildren {
				visit(children, depth: depth + 1)
			}
		}
	}
	visit(roots, depth: 0)
	return result
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

	@State private var exportDocument: TopicExportFileDocument?
	@State private var exportFormat: TopicExportFormat = .json
	@State private var showExporter = false

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

			Menu {
				MenuButton(title: "Copy as JSON", systemImage: "doc.on.doc", action: { copySubtree(.json) })
				MenuButton(title: "Copy as YAML", systemImage: "doc.on.doc", action: { copySubtree(.yaml) })
				MenuButton(title: "Export as JSON…", systemImage: "square.and.arrow.up", action: { exportSubtree(.json) })
				MenuButton(title: "Export as YAML…", systemImage: "square.and.arrow.up", action: { exportSubtree(.yaml) })
			} label: {
				Label("Export subtree", systemImage: "square.and.arrow.up.on.square")
			}
			.accessibilityIdentifier("export-subtree")

			MenuButton(title: "Mark as read", systemImage: "circlebadge", action: markRead)
				.accessibilityIdentifier("mark-as-read")

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

				MenuButton(
					title: "Remove from view",
					systemImage: "eye.slash.fill",
					action: removeFromView
				)
				.accessibilityIdentifier("confirm-remove-from-view")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityIdentifier("delete-retained")
		}
		.accessibilityIdentifier("folder: \(model.nameQualified)")
		.fileExporter(
			isPresented: $showExporter,
			document: exportDocument,
			contentType: exportFormat.contentType,
			defaultFilename: TopicExportNaming.filename(for: model.nameQualified)
		) { _ in }
	}

	func copyTopic() {
		Pasteboard.copy(model.nameQualified)
	}

	func copyName() {
		Pasteboard.copy(model.name)
	}

	func copySubtree(_ format: TopicExportFormat) {
		Pasteboard.copy(TopicTreeExporter.serialize(node: model, format: format))
	}

	func exportSubtree(_ format: TopicExportFormat) {
		exportFormat = format
		exportDocument = TopicExportFileDocument(
			text: TopicTreeExporter.serialize(node: model, format: format)
		)
		showExporter = true
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

	func markRead() {
		model.markRead()
	}

	func removeFromView() {
		model.remove()
	}
}
