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
		if host.state == .disconnected && messageModel.messageCount == 0 {
			if isCompact {
				// iPhone: show TopicsView which will auto-connect
				TopicsView(model: messageModel, host: host)
			} else {
				// iPad/Mac: show broker details, connect via sidebar
				BrokerDetailsView(host: host)
			}
		} else {
			TopicsView(model: messageModel, host: host)
		}
	}
}
