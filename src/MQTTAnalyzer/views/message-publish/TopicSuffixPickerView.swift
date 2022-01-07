//
//  TopicSuffixPickerView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-07.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicSuffixPickerView: View {
	@Binding var suffix: TopicSuffix
	
    var body: some View {
	  Picker(selection: $suffix, label: Text("Suffix")) {
		  Text("none").tag(TopicSuffix.none)
		  Text("set").tag(TopicSuffix.sset)
		  Text("get").tag(TopicSuffix.sget)
		  Text("state").tag(TopicSuffix.sstate)
	  }.pickerStyle(SegmentedPickerStyle())
    }
}
