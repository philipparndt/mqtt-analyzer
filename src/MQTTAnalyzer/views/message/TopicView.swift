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
		Section(header: Text("Topic")) {
			Text(node.nameQualified)
				.font(.subheadline)
				.foregroundColor(.gray).contextMenu {
					Button(action: copyTopic) {
						Text("Copy topic")
						Image(systemName: "doc.on.doc")
					}
				}
		}
	}
	
	func copyTopic() {
		Pasteboard.copy(node.nameQualified)
	}
}
