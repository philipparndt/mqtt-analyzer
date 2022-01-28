//
//  ConnectionTypePicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-13.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct NavigationPickerSectionView: View {
	@Binding var type: NavigationMode

	var body: some View {
		Section(header: Text("Navigation mode")) {
			NavigationPicker(type: $type)
		}
	}
}

struct NavigationPicker: View {
	@Binding var type: NavigationMode

	var body: some View {
		Picker(selection: $type, label: Text("Navigation")) {
			Text("Folders").tag(NavigationMode.folders)
			Text("Flat").tag(NavigationMode.classic)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
