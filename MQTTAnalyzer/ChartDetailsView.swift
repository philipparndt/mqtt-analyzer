//
//  ChartDetailsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-26.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import SwiftUICharts

struct ChartDetailsView : View {
    
    let title : String;
    
    var body: some View {
        VStack {
            ChartView(data: [59 - 50,58 - 50,56 - 50,57 - 50,62 - 50,58 - 50],
                      title: "",
                      legend: title, backgroundColor:Color(red: 226.0/255.0, green: 250.0/255.0, blue: 231.0/255.0) , accentColor:Color(red: 114.0/255.0, green: 191.0/255.0, blue: 130.0/255.0))
        }
    }
}

#if DEBUG
struct ChartDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        ChartDetailsView(title: "some title")
    }
}
#endif
