//
//  ConnectionTypePicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ProtocolVersionPickerSectionView: View {
	@Binding var version: HostProtocolVersion

	var body: some View {
		Section(header: Text("Version")) {
			ProtocolVersionPicker(version: $version)
		}
	}
}

struct ProtocolVersionPicker: View {
	@Binding var version: HostProtocolVersion

	var body: some View {
		Picker(selection: $version, label: Text("Version")) {
			Text("3.1.1").tag(HostProtocolVersion.mqtt3).accessibilityLabel("mqtt3")
			Text("5.0").tag(HostProtocolVersion.mqtt5).accessibilityLabel("mqtt5")
		}.pickerStyle(SegmentedPickerStyle())
	}
}
