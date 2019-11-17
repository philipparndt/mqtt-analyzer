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
            VStack (alignment: .leading) {
                List {
                    Section(header: Text("Topic")) {
                        Text(messagesByTopic.topic.name)
                    }
                    Section(header: Text("Value path")) {
                        Text(path.path)
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

#if DEBUG
//struct ChartDetailsView_Previews : PreviewProvider {
//    static var previews: some View {
//        ChartDetailsView(title: "some title")
//    }
//}
#endif
