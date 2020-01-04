//
//  QoSView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-29.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

import SwiftUI

struct QOSSectionView: View {
	@Binding var qos: Int

	var body: some View {
		Section(header: Text("QoS")) {
			QOSPicker(qos: $qos)
		}
	}
}

struct QOSPicker: View {
	@Binding var qos: Int

	var body: some View {
		Picker(selection: $qos, label: Text("QoS")) {
			Text("0").tag(0)
			Text("1").tag(1)
			Text("2").tag(2)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
