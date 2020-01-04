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

				Text(path.path)
				
				Spacer()
				
				Text(lastValue().stringValue)
					.font(.subheadline)
					.foregroundColor(.gray)
			}
		}
	}
	
	func lastValue() -> NSNumber {
		let last = self.messagesByTopic.getTimeSeriesLastValue(self.path)
		return last.map { $0.num } ?? 0
	}
}
