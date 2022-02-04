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
		Section(header: Text("Children")) {
			if model.childrenDisplay.isEmpty {
				Text(emptyTopicText)
					.foregroundColor(.secondary)
			}
			else {
				ForEach(model.childrenDisplay) { child in
					NavigationLink(destination: TopicsView(model: child, host: self.host)) {
						FolderCellView(model: child)
					}
					.accessibilityLabel("folder: \(child.nameQualified)")
				}
			}
		}
    }
}

struct FolderCellView: View {
	@ObservedObject var model: TopicTree

	var body: some View {
		HStack {
			FolderReadMarkerView(read: model.readState)
			
			Text(model.name)
			
			Spacer()

			CounterCellView(model: model)
		}
		.contextMenu {
			MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
			MenuButton(title: "Copy name", systemImage: "doc.on.doc", action: copyName)
	    }
	}
	
	func copyTopic() {
		UIPasteboard.general.string = model.nameQualified
	}

	func copyName() {
		UIPasteboard.general.string = model.name
	}
}

struct CounterCellView: View {
	@ObservedObject var model: TopicTree

	var body: some View {
		Text("\(model.topicCountDisplay)/\(model.messageCountDisplay)")
			.font(.system(size: 12, design: .monospaced))
			.foregroundColor(.secondary)
			.opacity(0.5)
	}
}
