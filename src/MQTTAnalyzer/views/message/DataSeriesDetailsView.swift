//
//  ChartDetailsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-26.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DataSeriesDetailsView: View {
	
	let path: DiagramPath
	@ObservedObject var node: TopicTree

	@State var range: Int = 60
	
	var body: some View {

		VStack {
			VStack(alignment: .leading) {
				List {
					Section(header: Text("Topic")) {
						Text(node.nameQualified)
					}
					Section(header: Text("Value path")) {
						Text(path.path)
					}
					Section(header: Text("Values")) {
						ForEach(node.timeSeries.getId(path).reversed()) {
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
