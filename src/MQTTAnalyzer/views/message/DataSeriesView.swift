//
//  DataSeriesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesView: View {
	@ObservedObject var node: TopicTree

	var body: some View {
		Group {
			//if leaf.timeSeries.hasTimeseries {
				Section(header: Text("Data series")) {
					ForEach(node.timeSeries.getDiagrams()) {
						DataSeriesCellView(
							path: $0,
							node: self.node,
							series: self.node.timeSeries
						)
					}
				}
			//}
		}
	}
}

struct DataSeriesCellView: View {
	let path: DiagramPath
	@ObservedObject var node: TopicTree
	@ObservedObject var series: TimeSeriesModel
	
	var body: some View {
		NavigationLink(destination: DataSeriesDetailsView(path: path, node: node)) {
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
		return series.getLastValue(path)
			.map { $0.valueString } ?? "<no value>"
	}
}
