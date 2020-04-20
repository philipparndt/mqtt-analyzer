//
//  ClientImplTypePicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ClientImplTypePickerSectionView: View {
	@Binding var type: HostClientImplType

	var body: some View {
		Section(header: Text("Client implementation")) {
			ClientImplTypePicker(type: $type)
		}
	}
}

struct ClientImplTypePicker: View {
	@Binding var type: HostClientImplType

	var body: some View {
		Picker(selection: $type, label: Text("Client")) {
			Text("CocoaMQTT").tag(HostClientImplType.cocoamqtt)
			Text("Moscapsule").tag(HostClientImplType.moscapsule)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
