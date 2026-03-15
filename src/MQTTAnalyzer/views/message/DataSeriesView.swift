//
//  DataSeriesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesSkippedView: View {
	var body: some View {
		Section(header: Text("Data series")) {
			HStack(spacing: 8) {
				Image(systemName: "chart.line.uptrend.xyaxis")
					.foregroundColor(.secondary)
				VStack(alignment: .leading, spacing: 2) {
					Text("Charts disabled for large payloads")
						.font(.subheadline)
					Text("Payload exceeds 50KB threshold")
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.padding(.vertical, 4)
		}
	}
}

struct DataSeriesView: View {
	let topic: String
	@ObservedObject var series: TimeSeriesModel

	private let initialLimit = 8
	@State private var isExpanded = false

	var body: some View {
		Group {
			if series.hasTimeseries {
				Section(header: Text("Data series")) {
					let diagrams = series.getDiagrams()
					let displayedDiagrams = isExpanded ? diagrams : Array(diagrams.prefix(initialLimit))

					ForEach(displayedDiagrams) {
						DataSeriesCellView(
							path: $0,
							topic: self.topic,
							series: self.series
						)
					}

					if diagrams.count > initialLimit {
						Button {
							withAnimation {
								isExpanded.toggle()
							}
						} label: {
							HStack {
								Spacer()
								Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
								Text(isExpanded ? "Show less" : "Show \(diagrams.count - initialLimit) more")
								Spacer()
							}
							.foregroundColor(.blue)
						}
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
