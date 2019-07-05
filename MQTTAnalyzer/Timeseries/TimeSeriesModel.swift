//
//  TimeSeriesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-05.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

struct MTimeSeriesValue {
    let value : NSNumber
    let timestamp : Date
}

struct MTimeSeriesMeanValue {
    let meanValue : Int?
}

class MTimeSeriesModel {

    var values : [MTimeSeriesValue] = []
    
    func getMeanValue(amount segements : Int, in rangeHours : Int, to end: Date) -> [MTimeSeriesMeanValue] {
        // MARK: TODO Subscript for mean values in range
        
        let distance = TimeInterval((rangeHours * 60 * 60) / segements)
        let start = end.advanced(by: -distance)
        
        let inRange = valuesInRange(values: values, from: start, to: end)
        
        var current = end
        var result = [MTimeSeriesMeanValue]()
        for _ in 1...segements {
            let next = current.advanced(by: -distance)
            
            let valuesInCurrentRange = valuesInRange(values: inRange, from: next, to: current)
            let value = buildMean(value: valuesInCurrentRange)
            
            current = next
            result.insert(value, at: 0)
        }
        
        return result
    }
    
    func valuesInRange(values: [MTimeSeriesValue], from start: Date, to end: Date) -> [MTimeSeriesValue] {
        return values.filter {
            return $0.timestamp.distance(to: start) <= 0
                && $0.timestamp.distance(to: end) >= 0
        }
    }
    
    func buildMean(value range: [MTimeSeriesValue]) -> MTimeSeriesMeanValue {
        if (range.isEmpty) {
            return MTimeSeriesMeanValue(meanValue: nil)
        }
        else {
            let total = range
                .map { $0.value.intValue }
                .reduce(0, +)
            
            return MTimeSeriesMeanValue(meanValue: total / range.count)
        }
    }
}
