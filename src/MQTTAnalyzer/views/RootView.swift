//
//  RootView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-02.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// The selected topic, so that following it does not mean re-rendering the
/// columns that only need to write to it.
final class TopicSelection: ObservableObject {
	@Published var topic: TopicTree?

	var binding: Binding<TopicTree?> {
		Binding(get: { self.topic }, set: { self.topic = $0 })
	}
}

/// Shows the messages of the selected topic. The only view that observes the
/// selection, so a selection change redraws this and nothing else.
struct TopicDetailColumn: View {
	@ObservedObject var selection: TopicSelection
	let broker: BrokerSetting?
	let rootModel: RootModel

	var body: some View {
		NavigationStack {
			if let topic = selection.topic, let broker = broker {
				MessagesView(node: topic, host: rootModel.getConnectionModel(broker: broker))
			} else {
				ContentUnavailableView(
					"No Topic Selected",
					systemImage: "doc.text",
					description: Text("Select a topic from the tree to view messages.")
				)
			}
		}
		.id(selection.topic?.id)
	}
}

struct RootView: View {
	@EnvironmentObject var model: RootModel
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@AppStorage(Welcome.key) var welcome: Bool = true

	@State private var selectedBroker: BrokerSetting?
	/// Held by reference rather than as state of this view: reading it here would
	/// re-render every column on every selection change, and re-rendering the topic
	/// list costs tens of milliseconds once it holds a few thousand rows.
	@State private var selection = TopicSelection()
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	var body: some View {
		Group {
			#if os(macOS)
			threeColumnLayout
			#else
			if horizontalSizeClass == .compact {
				twoColumnLayout
			} else {
				threeColumnLayout
			}
			#endif
		}
		.sheet(isPresented: $welcome, onDismiss: closeWelcome, content: {
			WelcomeView(closeHandler: closeWelcome)
				#if os(macOS)
				.frame(width: 500, height: 620)
				#endif
		})
	}

	// MARK: - Two Column Layout (iPhone)
	var twoColumnLayout: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			HostsView(hostsModel: model.hostsModel, selectedBroker: $selectedBroker)
		} detail: {
			NavigationStack {
				if let broker = selectedBroker {
					let host = model.getConnectionModel(broker: broker)
					let messageModel = model.getMessageModel(host)
					BrokerContentView(host: host, messageModel: messageModel)
				} else {
					ContentUnavailableView(
						"No Broker Selected",
						systemImage: "network",
						description: Text("Select a broker from the sidebar to view topics and messages.")
					)
				}
			}
		}
	}

	// MARK: - Three Column Layout (iPad/Mac)
	var threeColumnLayout: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			HostsView(hostsModel: model.hostsModel, selectedBroker: $selectedBroker)
				#if os(macOS)
				.navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
				#endif
		} content: {
			Group {
				if let broker = selectedBroker {
					let host = model.getConnectionModel(broker: broker)
					let messageModel = model.getMessageModel(host)
					TopicTreeSidebarView(
						host: host,
						model: messageModel,
						selectedTopic: selection.binding,
						selection: selection
					)
				} else {
					ContentUnavailableView(
						"No Broker Selected",
						systemImage: "network",
						description: Text("Select a broker from the sidebar.")
					)
				}
			}
			#if os(macOS)
			// Wide enough for the full topic paths the flat view shows
			.navigationSplitViewColumnWidth(min: 180, ideal: 300, max: 900)
			#endif
		} detail: {
			TopicDetailColumn(
				selection: selection,
				broker: selectedBroker,
				rootModel: model
			)
		}
		#if os(iOS)
		.navigationSplitViewStyle(.balanced)
		.onAppear {
			if selectedBroker == nil {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					columnVisibility = .all
				}
			}
		}
		.onChange(of: selectedBroker) {
			if selectedBroker != nil {
				columnVisibility = .doubleColumn
			}
		}
		#endif
	}

	func closeWelcome() {
		self.welcome = false
	}
}
