//
//  DataSeriesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesView: View {
	let topic: String
	@ObservedObject var series: TimeSeriesModel

	var body: some View {
		Group {
			if series.hasTimeseries {
				Section(header: Text("Data series")) {
					ForEach(series.getDiagrams()) {
						DataSeriesCellView(
							path: $0,
							topic: self.topic,
							series: self.series
						)
					}
				}
			}
		}
	}
}

struct DataSeriesCellView: View {
	let path: DiagramPath
	let topic: String
	@ObservedObject var series: TimeSeriesModel
	
	var body: some View {
		NavigationLink(destination: DataSeriesDetailsView(path: path, topic: topic, series: series)) {
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
