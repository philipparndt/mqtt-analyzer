//
//  TimeSeriesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-05.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

struct MTimeSeriesValue {
	let value: AnyHashable
	let timestamp: Date
}

struct MTimeSeriesMeanValue {
	let meanValue: Int?
}

class MTimeSeriesModel {
	var values: [MTimeSeriesValue] = []
}
