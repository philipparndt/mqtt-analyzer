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
				ForEach(model.childrenDisplay.sorted { $0.name < $1.name }) { child in
					NavigationLink(destination: TopicsView(model: child, host: self.host)) {
						FolderCellView(model: child, host: host)
					}
					.accessibilityLabel("folder: \(child.nameQualified)")
				}
			}
		}
    }
}

struct FolderCellView: View {
	@ObservedObject var model: TopicTree
	@EnvironmentObject var root: RootModel
	let host: Host
	
	var body: some View {
		HStack {
			FolderReadMarkerView(read: model.readState)
			
			Text(model.name.isBlank ? "<empty>" : model.name)
				.foregroundColor(model.name.isBlank ? .gray : .primary)
			
			Spacer()

			CounterCellView(model: model)
		}
		.contextMenu {
			MenuButton(title: "Copy topic", systemImage: "doc.on.doc", action: copyTopic)
			MenuButton(title: "Copy name", systemImage: "doc.on.doc", action: copyName)
			
			Menu {
				DestructiveMenuButton(title: "Delete retained messages from broker", systemImage: "trash.fill", action: deleteAllReatined)
					.accessibilityLabel("confirm-delete-broker")
			} label: {
				Label("Delete", systemImage: "trash.fill")
			}
			.accessibilityLabel("delete-broker")
	    }
	}
	
	func copyTopic() {
		UIPasteboard.general.string = model.nameQualified
	}

	func copyName() {
		UIPasteboard.general.string = model.name
	}
	
	func deleteAllReatined() {
		model.pauseAcceptEmptyFor(seconds: 5)
		
		let messages = model.allRetainedMessages
		for message in messages {
			root.publish(message: MsgMessage(
				topic: message.topic,
				payload: MsgPayload(data: []),
				metadata: MsgMetadata(qos: message.metadata.qos, retain: true)), on: host)
		}
		
		for message in messages {
			message.topic.delete(message: message)
		}
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
