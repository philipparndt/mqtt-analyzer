//
//  QuickFilterView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct QuickFilterView : View {
    
    @Binding
    var searchFilter : String
    
    var body: some View {
        HStack {
            TextField("Search", text: $searchFilter)
            .disableAutocorrection(true)
            
            Spacer()
            if (!searchFilter.isBlank) {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.gray)
                        .contextMenu {
                            Button(action: up) {
                                Text("Focus on parent")
                                Image(systemName: "eye.fill")
                            }
                        }
                }
            }
        }
    }
    
    func clearSearch() {
        searchFilter = ""
    }
    
    func up() {
        searchFilter = searchFilter.pathUp()
    }
}
