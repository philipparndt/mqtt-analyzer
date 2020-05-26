//
//  AuthPicker.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct CertificateLocationSectionView: View {
	@Binding var type: CertificateLocation
	
	var body: some View {
		Section(header: Text("Location")) {
			CertificateLocationPicker(type: $type)
		}
	}
}

struct CertificateLocationPicker: View {
	@Binding var type: CertificateLocation

	var body: some View {
		Picker(selection: $type, label: Text("Location")) {
			Text("Local").tag(CertificateLocation.local)
			Text("iCloud").tag(CertificateLocation.cloud)
		}.pickerStyle(SegmentedPickerStyle())
	}
}
