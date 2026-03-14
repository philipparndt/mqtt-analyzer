//
//  BrokerContentView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-04.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct BrokerContentView: View {
	@EnvironmentObject var rootModel: RootModel
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@ObservedObject var host: Host
	@ObservedObject var messageModel: TopicTree

	var isCompact: Bool {
		horizontalSizeClass == .compact
	}

	var body: some View {
		// Use consistent view structure to avoid view identity changes during state transitions
		if isCompact {
			// iPhone: always show TopicsView (it handles all states internally)
			TopicsView(model: messageModel, host: host)
		} else {
			// iPad/Mac: show details only when disconnected with no messages
			if host.state == .disconnected && messageModel.messageCount == 0 {
				BrokerDetailsView(host: host)
			} else {
				TopicsView(model: messageModel, host: host)
			}
		}
	}
}
