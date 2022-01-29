//
//  DataSeriesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesView: View {
	@ObservedObject var leaf: TopicTree

	var body: some View {
		Group {
			if leaf.hasDiagrams() {
				Text("Data series")
//				Section(header: Text("Data series")) {
//					ForEach(leaf.getDiagrams()) {
//						DataSeriesCellView(path: $0, messagesByTopic: self.messagesByTopic)
//					}
//				}
			}
		}
	}
}

struct DataSeriesCellView: View {
	let path: DiagramPath
	@ObservedObject var messagesByTopic: MessagesByTopic

	var body: some View {
		NavigationLink(destination: DataSeriesDetailsView(path: path, messagesByTopic: messagesByTopic)) {
			HStack {
				VStack {
					Image(systemName: PropertyImageProvider.byName(property: path.lastSegment))
						.font(.subheadline)
						.foregroundColor(.blue)
						
				}
				.frame(minWidth: 30, alignment: Alignment.center)
				
				VStack {
					HStack {
						Text(path.lastSegment)
						Spacer()
					}
					
					if path.hasSubpath {
						HStack {
							Text(path.parentPath)
								.font(.footnote)
								.foregroundColor(.gray)
							Spacer()
						}
					}
				}
				
				Spacer()
				
				Text(lastValue())
					.font(.subheadline)
					.foregroundColor(.gray)
			}
		}
	}
	
	func lastValue() -> String {
		return messagesByTopic.getTimeSeriesLastValue(path)
			.map { $0.valueString } ?? "<no value>"
	}
}
