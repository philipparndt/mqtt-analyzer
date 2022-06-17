//
//  ChartDetailsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-26.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Charts

struct DataSeriesDetailsView: View {
	
	let path: DiagramPath
	let topic: String
	@ObservedObject var series: TimeSeriesModel

	@State var range: Int = 60
	
	var body: some View {

		VStack {
			VStack(alignment: .leading) {
				List {
					Section(header: Text("Topic")) {
						Text(topic)
					}
					Section(header: Text("Value path")) {
						Text(path.path)
					}
					Section(header: Text("Values")) {
						Chart(series.getGrouped(path)) {
							AreaMark(
								x: .value("time", $0.date, unit: .minute),
								yStart: .value("min", Double($0.min)),
								yEnd: .value("max", Double($0.max))
							)
							.foregroundStyle(.cyan)
							
							LineMark(
								x: .value("time", $0.date, unit: .minute),
								y: .value("value", $0.average),
								series: .value("average", "average")
							)
							.foregroundStyle(.blue)
							.symbol(Circle())
						}
						.chartLegend(.visible)
						.frame(width: nil, height: 100)
						
						ForEach(series.getId(path).reversed()) {
							DataSeriesCell(path: $0)
						}
					}
				}
				.listStyle(GroupedListStyle())
			}
		}
	}
}

struct DataSeriesCell: View {
	let path: TimeSeriesValue
	
	var body: some View {
		HStack {
			Image(systemName: "number.circle.fill")
				.font(.subheadline)
				.foregroundColor(.blue)
			
			Text(path.valueString)
			Spacer()
			Text("\(path.dateString)").foregroundColor(.secondary)
		}
	}
}
