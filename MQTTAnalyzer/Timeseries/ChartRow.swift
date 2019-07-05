//
//  ChartRow.swift
//  ChartView
//
//  Created by András Samu on 2019. 06. 12..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct ChartRow : View {
    var data: [Int]
    var maxValue: Int {
        get {
            let result = data.max() ?? 1
            
            if (result != 0) {
                return result
            }
            else {
                return 1
            }
        }
    }
    public var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: (geometry.frame(in: .local).width-22)/CGFloat(self.data.count * 3)){
                ForEach(self.data) {
                    ChartCell(
                        value: Double($0) / Double(self.maxValue),
                        width: Float(geometry.frame(in: .local).width - 22),
                        numberOfDataPoints: self.data.count
                    )
                }
            }.padding([.trailing,.leading], 15)
        }
    }
}

#if DEBUG
struct ChartRow_Previews : PreviewProvider {
    static var previews: some View {
        ChartRow(data: [8,23,54,32,12,37,7])
    }
}
#endif
