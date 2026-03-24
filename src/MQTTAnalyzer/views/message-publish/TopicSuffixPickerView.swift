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
			  .accessibilityIdentifier("none")
		  Text("set").tag(TopicSuffix.sset)
			  .accessibilityIdentifier("set")
		  Text("get").tag(TopicSuffix.sget)
			  .accessibilityIdentifier("get")
		  Text("state").tag(TopicSuffix.sstate)
			  .accessibilityIdentifier("state")
	  }.pickerStyle(SegmentedPickerStyle())
    }
}
