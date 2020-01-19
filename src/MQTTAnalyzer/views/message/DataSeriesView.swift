//
//  DataSeriesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesView: View {
	@ObservedObject var messagesByTopic: MessagesByTopic

	var body: some View {
		Group {
			if messagesByTopic.hasDiagrams() {
				Section(header: Text("Data series")) {
					ForEach(messagesByTopic.getDiagrams()) {
						DataSeriesCellView(path: $0, messagesByTopic: self.messagesByTopic)
					}
				}
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
				Image(systemName: "chart.bar")
					.font(.subheadline)
					.foregroundColor(.blue)
				
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
