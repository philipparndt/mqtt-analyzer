//
//  TopicView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageTopicView: View {
	@ObservedObject var node: TopicTree

	var body: some View {
		Section {
			TopicPathView(topic: node.nameQualified)
				.listRowInsets(EdgeInsets())
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
		}
	}
}
