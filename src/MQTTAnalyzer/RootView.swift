//
//  RootView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-02.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI


struct RootView : View {
    @EnvironmentObject var model : RootModel

    var body: some View {
        HostsView(hostsModel: model.hostsModel)
//        TabView(selection: .constant(1)) {
//            HostsView().tabItem { Text("Tab Label 1") }.tag(1)
//            Text("Tab Content 2").tabItem { Text("Tab Label 2") }.tag(2)
//        }
    }
}
