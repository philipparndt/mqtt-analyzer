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
    @ObjectBinding var messagesByTopic: MessagesByTopic

    @State var range : Int = 60
    
    var body: some View {
        VStack {
            SegmentedControl(selection: $range) {
                Text("1h").tag(60)
                Text("6h").tag(60 * 6)
                Text("12h").tag(60 * 12)
                Text("1d").tag(60 * 24)
            }.padding()
            
            VStack (alignment: .leading) {
                List {
                    Section(header: Text("Diagram")) {
                        Chart(path: path, messagesByTopic: messagesByTopic)
                    }
                    Section(header: Text("Values")) {
                        ForEach(messagesByTopic.getTimeSeriesId(path)) {
                            ValueCell(path: $0)
                        }
                    }
                }.listStyle(.grouped)
            }
        }
    }
}

struct ValueCell : View {
    let path : IdentifiableNumber
    
    var body: some View {
        HStack {
            Image(systemName: "chart.bar")
                .font(.subheadline)
                .foregroundColor(.blue)
            
            VStack (alignment: .leading) {
                Text("\(path.num)")
            }
        }
    }
}

struct Chart : View {
    
    let path : DiagramPath
    @ObjectBinding var messagesByTopic: MessagesByTopic
    
    var body: some View {

        VStack {
            ZStack {
                ChartRow(data: messagesByTopic.getTimeSeriesInt(self.path))
                .foregroundColor(.blue)
            }.frame(height: CGFloat(150))
            
//            ChartView(data: messagesByTopic.getTimeSeriesInt(self.path),
//                      title: "",
//                      legend: path.path, backgroundColor:Color(red: 226.0/255.0, green: 250.0/255.0, blue: 231.0/255.0) , accentColor:Color(red: 114.0/255.0, green: 191.0/255.0, blue: 130.0/255.0))
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
