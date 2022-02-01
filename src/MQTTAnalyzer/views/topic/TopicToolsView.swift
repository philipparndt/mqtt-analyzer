//
//  TopicToolsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsToolsView: View {
	@ObservedObject var model: TopicTree
		
	var body: some View {
		Group {
			HStack {
				Text("Topics/Messages")
				Spacer()
				Text("\(model.topicCount)/\(model.messageCount)")
				
				Button(action: model.markRead) {
					Button(action: noAction) {
						Image(systemName: "line.horizontal.3.decrease.circle")
							.foregroundColor(.gray)
							
					}.contextMenu {
						Button(action: model.clear) {
							Text("Clear")
							Image(systemName: "bin.xmark")
						}
						Button(action: model.markRead) {
							Text("Mark all as read")
							Image(systemName: "eye.fill")
						}
					}
				}
			}
			
			if model.parent != nil {
				HStack {
					Text("Topic")
					Spacer()
					if #available(macCatalyst 15.0, *) {
						Text(model.nameQualified)
							.textSelection(.enabled)
					} else {
						// Fallback on earlier versions
						Text(model.nameQualified)
					}
				}
			}
		}
	}
	
	private func noAction() {
		
	}
}
