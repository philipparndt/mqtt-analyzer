//
//  RootView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-02.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct RootView: View {
	@EnvironmentObject var model: RootModel
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@AppStorage(Welcome.key) var welcome: Bool = true

	@State private var selectedBroker: BrokerSetting?
	@State private var selectedTopic: TopicTree?
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
						selectedTopic: $selectedTopic
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
			.navigationSplitViewColumnWidth(min: 180, ideal: 300, max: 500)
			#endif
		} detail: {
			NavigationStack {
				if let topic = selectedTopic, let broker = selectedBroker {
					let host = model.getConnectionModel(broker: broker)
					MessagesView(node: topic, host: host)
				} else {
					ContentUnavailableView(
						"No Topic Selected",
						systemImage: "doc.text",
						description: Text("Select a topic from the tree to view messages.")
					)
				}
			}
			.id(selectedTopic?.id)
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
