//
//  ChartDetailsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-26.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ChartDetailsView : View {
    
    let path : DiagramPath
    @ObservedObject var messagesByTopic: MessagesByTopic

    @State var range : Int = 60
    
    var body: some View {

        VStack {
            Picker(selection: $range, label: Text("")) {
                Text("1h").tag(60)
                Text("6h").tag(60 * 6)
                Text("12h").tag(60 * 12)
                Text("1d").tag(60 * 24)
                }.pickerStyle(SegmentedPickerStyle()).padding()
            
            VStack (alignment: .leading) {
                List {
                    Section(header: Text("Diagram Demo")) {
                        ChartDemo()
                    }
                    Section(header: Text("Diagram")) {
                        Chart(path: path, messagesByTopic: messagesByTopic)
                    }
                    Section(header: Text("Values")) {
                        ForEach(messagesByTopic.getTimeSeriesId(path).reversed()) {
                            ValueCell(path: $0)
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
        }
    }
}

struct ValueCell : View {
    let path : TimeSeriesValue
    
    var body: some View {
        HStack {
            Image(systemName: "number.circle.fill")
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Text("\(path.num)")
            Spacer()
            Text("\(path.dateString)").foregroundColor(.secondary)
        }
    }
}

struct Chart : View {
    
    let path : DiagramPath
    @ObservedObject var messagesByTopic: MessagesByTopic
    
    var body: some View {

        VStack {
            ZStack {
                ChartRow(data: messagesByTopic.getValuesLastHour(self.path))
                .foregroundColor(.blue)
            }.frame(height: CGFloat(150))
        }
    }
}

struct ChartDemo : View {
    
    var body: some View {
        
        VStack {
            ZStack {
                ChartRow(data: [1,2,3,4,5,6,7,8,9,0,
                                1,2,3,4,5,6,7,8,9,0,
                                1,2,3,4,5,6,7,8,9,0,
                                1,2,3,4,5,6,7,8,9,0,
                                1,2,3,4,5,6,7,8,9,0,
                                1,2,3,4,5,6,7,8,9,0,
                              ])
                    .foregroundColor(.blue)
            }.frame(height: CGFloat(150))
        }
    }
}

#if DEBUG
//struct ChartDetailsView_Previews : PreviewProvider {
//    static var previews: some View {
//        ChartDetailsView(title: "some title")
//    }
//}
#endif
