//
//  QuickFilterView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-16.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct QuickFilterView : View {
    
    @ObservedObject
    var model : MessageModel
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: Binding(
            get: {
                return self.model.filter
            },
            set: { (newValue) in
                return self.model.filter = newValue
            }))
            .disableAutocorrection(true)
            
            Spacer()
            if (!model.filter.isBlank) {
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
        model.filter = ""
    }
    
    func up() {
        model.filter = model.filter.pathUp()
    }
}
