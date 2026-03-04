//
//  RootView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-02.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Highlightr

struct RootView: View {
	@EnvironmentObject var model: RootModel
	@Environment(\.managedObjectContext) private var viewContext

	@AppStorage(Welcome.key) var welcome: Bool = true

	@State private var selectedBroker: BrokerSetting?
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			HostsView(hostsModel: model.hostsModel, selectedBroker: $selectedBroker)
		} detail: {
			NavigationStack {
				if let broker = selectedBroker {
					let host = model.getConnectionModel(broker: broker)
					let messageModel = model.getMessageModel(host)
					TopicsView(model: messageModel, host: host)
				} else {
					ContentUnavailableView(
						"No Broker Selected",
						systemImage: "network",
						description: Text("Select a broker from the sidebar to view topics and messages.")
					)
				}
			}
		}
		.sheet(isPresented: $welcome, onDismiss: closeWelcome, content: {
			WelcomeView(closeHandler: closeWelcome)
		})
	}

	func closeWelcome() {
		self.welcome = false
	}
}
