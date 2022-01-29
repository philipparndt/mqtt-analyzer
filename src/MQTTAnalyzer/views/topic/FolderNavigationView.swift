//
//  FolderNavigationView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-29.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct FolderNavigationView: View {
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
			}
			else {
				ForEach(model.childrenDisplay) { child in
					NavigationLink(destination: TopicsView(model: child, host: self.host)) {
						HStack {
							Image(systemName: "folder.fill")
								.foregroundColor(.blue)
							Text(child.name)
							
							Spacer()

							Text("\(child.topicCountDisplay)/\(child.messageCountDisplay)")
								.font(.system(size: 12, design: .monospaced))
								.foregroundColor(.secondary)
								.opacity(0.5)
						}
					}
				}
			}
		}
    }
}
