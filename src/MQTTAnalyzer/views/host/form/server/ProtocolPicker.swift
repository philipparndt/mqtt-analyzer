//
//  ConnectionTypePicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ConnectionMethodPickerSectionView: View {
	@Binding var type: HostProtocol

	var body: some View {
		Section(header: Text("Protocol")) {
			ProtocolPicker(type: $type)
		}
	}
}

struct ProtocolPicker: View {
	@Binding var type: HostProtocol

	var body: some View {
		Picker(selection: $type, label: Text("Protocol")) {
			Text("MQTT").tag(HostProtocol.mqtt)
			Text("Websocket").tag(HostProtocol.websocket)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
