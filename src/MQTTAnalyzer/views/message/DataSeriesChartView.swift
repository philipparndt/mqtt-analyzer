//
//  DataSeriesChartView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 18.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Charts

struct DataSeriesChartView: View {
	var axis: Visibility = .visible
	let path: DiagramPath
	@ObservedObject var series: TimeSeriesModel
	
    var body: some View {
		if !series.canPlot(path) {
			EmptyView()
		}
		else {
			Chart(series.getGrouped(path)) {
				AreaMark(
					x: .value("time", $0.date, unit: .minute),
					yStart: .value("min", Double($0.min)),
					yEnd: .value("max", Double($0.max))
				)
				.interpolationMethod(.monotone)
				.foregroundStyle(.blue)
				.opacity(0.3)
				
				LineMark(
					x: .value("time", $0.date, unit: .minute),
					y: .value("value", $0.average),
					series: .value("average", "average")
				)
				.interpolationMethod(.monotone)
				.foregroundStyle(.blue)
				.symbol(Circle())
				.symbolSize(16)
			}
			.chartXAxis(axis)
			.chartYAxis(axis)
		}
    }
}
